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
  ' ':
    name: 'other'
    frames: [54..56]

animations = {}

for char, data of tileTypes
  animations[char] = frames: data.frames


class Tile
  constructor: (spriteSheet, char, x, y) ->
    @tile = new createjs.BitmapAnimation(spriteSheet)

    frames = tileTypes[char].frames
    index = _.shuffle(frames)[0]

    @tile.gotoAndStop(index)
    @tile.x = x * 40
    @tile.y = y * 40


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

        tile = new Tile @spriteSheet, char, cursorX, cursorY
        @stage.addChild tile.tile


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

  socket = io.connect("http://#{location.hostname}:8000")
  socket.on('map', (map) ->
    ui.map = map
    ui.renderMap()
  )

  socket.on('world state', (data) ->
    for item in data.items
      tile = new Tile ui.spriteSheet, 't', item.x, item.y
      ui.stage.addChild tile.tile

    for player in data.players
      tile = new Tile ui.spriteSheet, 'p', player.x, player.y
      ui.stage.addChild tile.tile
  )

  socket.on('connect', ->
    socket.emit("visualizer", {})
  )
