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

  registerOrder: (clientId, order) ->
    @orders[clientId] = order

  validMove: (player, direction) ->
    newPos = @translatePosition player.position(), direction
    @isFloor(newPos)

  translatePosition: (position, direction) ->
    pos = _.clone(position)
    if direction.match /n/ then pos.y -= 1
    if direction.match /s/ then pos.y += 1
    if direction.match /e/ then pos.x += 1
    if direction.match /w/ then pos.x -= 1
    pos


  processAttacks: (attacks) ->
    for attack in attacks
      if @validAttack(attack)
        console.log "ATTACKED"
        # DMG player

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
    @playerMessages = {}
    messages = _.values(@orders)
    @processAttacks _(messages, (msg) -> msg.command == "attack")
    @killDeadPlayers()
    @pickupTreasure _(messages, (msg) -> msg.command == "acquire")
    # @dropTreasure _(messages, (msg) -> msg.command == "drop")
    # @processMoves  _(messages, (msg) -> msg.command == "move")
    @orders = {}

  tickPayloadFor: (clientId) ->
    player = @findPlayer(clientId)
    you: player.tickPayload()
    vision: @surroundingTiles(player.position())

  findPlayer: (clientId) ->
    _.find(@players, (p) -> p.clientId == clientId)

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