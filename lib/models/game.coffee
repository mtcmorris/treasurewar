require('./dungeon')
_ = require('underscore')
require('./player')

root.Game = class Game
  constructor: ->
    @mapX = 0
    @mapY = 0
    @map = null
    @players = []

  spawnDungeon: (x, y) ->
    @mapX = x
    @mapY = y
    dungeon = new Dungeon(@mapX, @mapY)

    @map = dungeon.generate()

  spawnPlayer: ->
    player = new Player(@getRandomFloorLocation())
    @players.push player

  getRandomFloorLocation: ->
    throw("There is no dungeon") if @map is null
    while(true)
      x = parseInt(Math.random() * @mapX)
      y = parseInt(Math.random() * @mapY)

      if @map[y][x] is ' '
        return {x: x, y: y}

  isFloor: (position) ->
    @map[position.y][position.x] == ' '

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

  killDeadPlayers: ->
    for player in players
      if player.health < 0
        player.kill()

  pickupTreasure: (orders) ->
    for order in orders
      if @treasureAtLocation(order)
        # Do sometjing
        console.log "Treasure acquired"

  tick: (messages) ->
    @processAttacks _(messages, (msg) -> msg.command == "attack")
    @killDeadPlayers()
    @pickupTreasure _(messages, (msg) -> msg.command == "acquire")
    # @dropTreasure _(messages, (msg) -> msg.command == "drop")
    # @processMoves  _(messages, (msg) -> msg.command == "move")

  tickMessageFor: (player) ->

  mapToString: ->
    output = "The Map\n"
    _.each @map, (row, y) ->
      output += row + "\n"
    output