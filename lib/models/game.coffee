require('./dungeon')
_ = require('underscore')
require('./player')

root.Game = class Game
  constructor: ->
    @mapX = 0
    @mapY = 0
    @map = null
    @players = []
    @orders = {}
    @playerMessages = {}

  spawnDungeon: (x, y) ->
    @mapX = x
    @mapY = y
    dungeon = new Dungeon(@mapX, @mapY)

    @map = dungeon.generate()

  spawnPlayer: (clientId) ->
    player = new Player(clientId, @getRandomFloorLocation())
    @players.push player

  setName: (clientId, name) ->
    @findPlayer(clientId).name = name

  disconnectPlayer: (clientId) ->
    @players = _.reject(@players, (p) -> p.clientId == clientId)

  getRandomFloorLocation: ->
    throw("There is no dungeon") if @map is null
    while(true)
      x = parseInt(Math.random() * @mapX)
      y = parseInt(Math.random() * @mapY)

      if @map[y][x] is ' '
        return {x: x, y: y}

  isFloor: (position) ->
    @map[position.y][position.x] == ' '

  registerOrder: (order) ->
    console.log "Order received"
    @orders[order.clientId] = order

  validMove: (player, direction) ->
    newPos = @translatePosition player.position(), direction
    @isFloor(newPos)

  movePlayer: (player, direction) ->
    newPos = @translatePosition player.position(), direction
    player.x = newPos.x
    player.y = newPos.y

  translatePosition: (position, direction) ->
    pos = _.clone(position)
    if direction.match /n/ then pos.y -= 1
    if direction.match /s/ then pos.y += 1
    if direction.match /e/ then pos.x += 1
    if direction.match /w/ then pos.x -= 1
    pos


  processAttacks: (attacks) ->
    for attack in attacks
      attacked = @validAttack(attack)
      if attacked
        attacked.hp -= 10
        @messageClient(attacked, notice: "You were attacked by #{attack.player.name}")

  messageClient: (player, msg) ->
    @playerMessages[player.clientId] ||= []
    @playerMessages[player.clientId].push msg

  validAttack: (attack) ->
    # Need attacker, attackee
    attackedPosition = @translatePosition attack.player.position(), attack.dir
    @findPlayerByPosition attackedPosition

  killDeadPlayers: ->
    for player in @players
      if player.health < 0
        player.kill()

  pickupTreasure: (orders) ->
    for order in orders
      if @treasureAtLocation(order)
        # Do sometjing
        console.log "Treasure acquired"

  tick: ->
    console.log "Ticking!"
    @playerMessages = {}
    orders = _.values(@orders)
    console.log "Running orders"
    console.log orders
    @processAttacks _.filter(orders, (order) -> order.command == "attack")
    @pickupTreasure _.filter(orders, (order) -> order.command == "pick up")
    # @throwTreasure _(messages, (msg) -> msg.command == "throw")

    moves = _.filter(orders, (order) -> order.command == "move")
    @processMoves moves
    # @respawnDeadPlayers()
    @orders = {}

  processMoves: (moveOrders) ->
    for order in moveOrders
      player = @findPlayer(order.clientId)

      if @validMove(player, order.payload?.dir)
        @movePlayer(player, order.payload?.dir)
        @messageClient(player, notice: "You moved #{order.payload?.dir}")
      else
        @messageClient(player, error: "Invalid move dir: #{order.payload?.dir}")



  tickPayloadFor: (clientId) ->
    player = @findPlayer(clientId)

    {
      messages: @playerMessages[clientId] || []
      you: player.tickPayload()
      tiles: @surroundingTiles(player.position())
      nearby_players: _(@findNearbyPlayers(player)).map((p) -> p.anonPayload())
      nearby_stashes: @findNearbyStashes(player)
      nearby_treasure: []
    }


  findPlayer: (clientId) ->
    _.find(@players, (p) -> p.clientId == clientId)

  findNearbyPlayers: (player) ->
    pos = player.position()
    _.filter(_.without(@players, player), (p) ->
      Math.abs(p.x - pos.x) <= 1 && Math.abs(p.y - pos.y) <= 1
    )

  findNearbyStashes: (player) ->
    pos = player.position()
    _.filter(_.without(@players, player), (p) ->
      Math.abs(p.stash.x - pos.x) <= 1 && Math.abs(p.stash.y - pos.y)
    ).map((p) -> {
      x: p.stash.x,
      y: p.stash.y,
      name: p.name
      treasure: p.stash.treasure
    })


  findPlayerByPosition: (pos) ->
    _.find(@players, (p) -> p.x == pos.x && p.y == pos.y)

  surroundingTiles: (pos) ->
    {
      n: @map[pos.y - 1][pos.x]
      ne: @map[pos.y - 1][pos.x + 1]
      e: @map[pos.y][pos.x + 1]
      se: @map[pos.y + 1][pos.x + 1]
      s: @map[pos.y + 1][pos.x]
      sw: @map[pos.y + 1][pos.x - 1]
      w: @map[pos.y][pos.x - 1]
      nw: @map[pos.y - 1][pos.x - 1]

    }

  mapToString: ->
    output = "The Map\n"
    _.each @map, (row, y) ->
      output += row + "\n"
    output