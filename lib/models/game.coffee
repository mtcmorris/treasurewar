require('./dungeon')
_ = require('underscore')
require('./player')
require('./order')
require('./treasure')

root.Game = class Game
  constructor: ->
    @mapX = 0
    @mapY = 0
    @map = null
    @players = []
    @orders = {}
    @playerMessages = {}
    @treasures = []


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
      return {x, y} if @isFloor({y, x})

  isFloor: (position) ->
    @map[position.y][position.x] == 'f'

  registerOrder: (order) ->
    console.log "Order received", order
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

  processAttacks: (attack_orders) ->
    for attack in attack_orders
      attacked = @validAttack(attack)
      if attacked
        attacked.health -= 10
        @messageClient(attack.player, notice: "You attacked #{attacked.name}")
        @messageClient(attacked, notice: "You were attacked by #{attack.player.name}")
        if attacked.health <= 0
          attack.player.kills += 1
      else
        @messageClient(attack.player, error: "Your attack in dir #{attack.dir} where there was no player")

  processPickups: (pickup_orders) ->
    for order in pickup_orders
      #TODO refactor to support other item types
      player = @findPlayer(order.clientId)
      if item = @getTreasureAtPosition(player.position())
        console.log "#{player.name} picked up #{item.type} at #{item.position()}"
        player.pickup(item)
        @messageClient(player, notice: "You picked up #{item.type}")
      else
        @messageClient(player, error: "Nothing to pick up here")



  messageClient: (player, msg) ->
    @playerMessages[player.clientId] ||= []
    @playerMessages[player.clientId].push msg

  validAttack: (attack) ->
    attackedPosition = @translatePosition attack.player.position(), attack.dir
    @findPlayerByPosition attackedPosition

  pickupTreasure: (orders) ->
    for order in orders
      player = @findPlayer(order.clientId)
      if treasure = @getTreasureAtPosition(player.position())
        player.takeTreasure(treasure)
        console.log "Treasure acquired by #{player.name}"

  dropTreasure: (orders) ->
    for order in orders
      player = @findPlayer(order.clientId)
      if treasure = @getTreasureAtPosition(player.position())
        player.takeTreasure(treasure)
        console.log "Treasure acquired by #{player.name}"

  tick: ->
    console.log "Tick"
    @playerMessages = {}

    orders = _.values(@orders)
    _(orders).map (o) =>
      o.player = @findPlayer(o.clientId)

    @processAttacks _.filter(orders, (order) -> order.command == "attack")
    @pickupTreasure _.filter(orders, (order) -> order.command == "pick up")
    # @throwTreasure _(messages, (msg) -> msg.command == "throw")
    @processMoves _.filter(orders, (order) -> order.command == "move")
    @respawnDeadPlayers()
    @repopTreasure()
    @updateScores()

    @orders = {}

  respawnDeadPlayers: ->
    deadPlayers = _(@players).filter( (p) -> p.health <= 0)

    for player in deadPlayers
      player.respawn()
      @messageClient(player, notice: "You died :(")

  processMoves: (moveOrders) ->
    for order in moveOrders
      return unless order.player?
      if @validMove(order.player, order.dir)
        @movePlayer(order.player, order.dir)
        @messageClient(order.player, notice: "You moved #{order.dir}")
      else
        @messageClient(order.player, error: "Invalid move dir: #{order.dir}")

  updateScores: -> player.calcScore() for player in @players

  tickPayloadFor: (clientId) ->
    player = @findPlayer(clientId)

    {
      messages: @playerMessages[clientId] || []
      you: player.tickPayload()
      tiles: @visibleTiles(player.position())
      nearby_players: _(@findNearbyPlayers(player)).map((p) -> p.anonPayload())
      nearby_stashes: @findNearbyStashes(player)
      nearby_treasure: []
    }

  visualizerTickPayload: ->
    {
      players: @players
      treasures: @treasures
    }


  findPlayer: (clientId) ->
    _.find(@players, (p) -> p.clientId == clientId)

  findNearbyPlayers: (player) ->
    pos = player.position()
    _.filter(_.without(@players, player), (p) ->
      Math.abs(p.x - pos.x) <= 2 && Math.abs(p.y - pos.y) <= 2
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

  visibleTiles: (pos) ->
    visible = []
    for k in [-2, -1, 0, 1, 2]
      for j in [-2, -1, 0, 1, 2]
        tile = @map[pos.y + k][pos.x + j] if @map[pos.y + k]

        if tile and tile is 'W'
          visible.push {x: pos.x + j, y: pos.y + k, type: "wall"}
    visible

  mapToString: ->
    output = "The Map\n"
    _.each @map, (row, y) ->
      output += row + "\n"
    output

  getTreasureAtPosition: (position) ->
    # return the treasure object at position or null if none there
    treasures = _.filter(@treasures, (treasure) -> treasure.position().x == position.x && treasure.position().y == position.y)
    treasure = if treasures.length > 0 then treasures[0] else null

  repopTreasure: ->
    # repop one treasure per player somewhere random in the dungeon
    while @treasures.length < @players.length
      position = @getRandomFloorLocation()
      treasure_already_at_location = @getTreasureAtPosition(position)
      if not treasure_already_at_location
        @treasures.push new Treasure(position)


