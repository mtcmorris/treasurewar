tileTypes =
  'W':
    name: 'walls'
    frames: [42..44]
  'f':
    name: 'floors'
    frames: [48..50]
  'p':
    name: 'players'
    frames: [0..5]
  't':
    name: 'treasures'
    frames: [36..38]
  'h':
    name: 'health'
    frames: [30..35]
  's':
    name: 'stash'
    frames: [54..56]
  ' ':
    name: 'other'
    frames: [54..56]

animations = {}

for char, data of tileTypes
  animations[char] = frames: data.frames


class Tile

  constructor: (@stage, spriteSheet, char) ->
    @tile = new createjs.BitmapAnimation(spriteSheet)

    frames = tileTypes[char].frames
    @index = _.shuffle(frames)[0]
    @stage.addChild @tile

  draw: (x, y, index) ->
    @tile.gotoAndStop(index || @index)
    @tile.x = x * 40
    @tile.y = y * 40


class Player
  constructor: (ui, sprite) ->
    @tile = new Tile(ui.stage, ui.spriteSheet, 'p')
    @healthBar = new Tile(ui.stage, ui.spriteSheet, 'h')
    @baseIndex = @tile.index

  update: (data) ->
    index = @baseIndex
    if data.health < 50
      index += 12
    if data.carry_treasure
      index += 6
    @tile.draw(data.x, data.y, index)


class Stash
  constructor: (ui, sprite) ->
    @tile = new Tile(ui.stage, ui.spriteSheet, 'p')

  update: (data, index) ->
    @tile.draw(data.stash.x, data.stash.y, index + 12)


class Treasure
  constructor: (ui, sprite) ->
    @tile = new Tile(ui.stage, ui.spriteSheet, 't')

  update: (data) ->
    @tile.draw(data.x, data.y)


class TreasureWarUI
  renderMap: () ->
    return unless @map && @spritesReady

    width = 100
    height = 100

    for cursorY in [0..height]
      for cursorX in [0..width]
        continue if @map.length <= cursorY
        continue if @map[cursorY].length <= cursorX

        char = @map[cursorY][cursorX]

        tile = new Tile @stage, @spriteSheet, char
        tile.draw cursorX, cursorY


  tick: ->
    if @spriteSheet.complete
      createjs.Ticker.removeListener @
      @spritesReady = true
      @renderMap()


  main: ->
    @spriteSheet = new createjs.SpriteSheet
      images: ["sprite.png"]
      animations: animations
      frames: {width: 40, height: 40}

    createjs.Ticker.addListener @

    @stage = new createjs.Stage("TreasureWar")
    createjs.Ticker.addListener @stage


$ ->
  ui = new TreasureWarUI
  ui.main()
  players = {}
  stashes = {}
  treasures = {}

  socket = io.connect("http://#{location.hostname}:8000")
  socket.on('map', (map) ->
    ui.map = map
    ui.renderMap()
  )

  socket.on('world state', (data) ->
    for treasure in data.items
      # need to remove treasure that have been picked up
      t = (treasures[treasure.clientId] ?= new Treasure(ui))
      t.update(treasure)

    for player in data.players
      p = (players[player.clientId] ?= new Player(ui))
      p.update(player)

    for id, p of players
      s = (stashes[player.clientId] ?= new Stash(ui))
      s.update(player, p.tile.index)


    $("#leaderboard").empty()
    asc_players = _(data.players).sortBy (p) -> p.score * -1
    for player in asc_players
      console.log player
      div = """<div>
        <h1>#{player.name}</h1>
        <h2>#{player.score}</h2>
      </div>
      """
      $("#leaderboard").append div

  )

  socket.on('connect', ->
    socket.emit("visualizer", {})
  )
