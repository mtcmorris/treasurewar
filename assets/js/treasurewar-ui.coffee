

tileTypes =
  'W':
    name: 'walls'
    frames: [42..45]
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
    frames: [54..57]

animations = {}

for char, data of tileTypes
  animations[char] = frames: data.frames


class Sprites

  constructor: (sprites) ->
    @spritesheet = new createjs.SpriteSheet
      images: [sprites]
      animations: animations
      frames: {width: 40, height: 40}
    @sprite = new createjs.BitmapAnimation @spritesheet

  show: (index, stage, x, y) ->

    stage.addChild @sprite
    @sprite.gotoAndStop index
    @sprite.x = x
    @sprite.y = y


class TreasureWarUI

  constructor: ->
    @loaded = 0

  handleImageLoad: (event) =>
    @loaded = @loaded + 1
    #console.log @loaded

  randomFrame: (frames) ->
    _.shuffle(frames)[0]

  randomSprite: (char, pos) ->
    s = new Sprites @sprites
    index = @randomFrame tileTypes[char].frames
    s.show index, @stage, pos.x * 40, pos.y * 40
    @stage.update()

  placeFloorTile: (pos) ->
    @randomSprite 'f', pos

  renderMap: (@map) ->
    width = 40
    height = 40

    for cursorY in [0..height]
      for cursorX in [0..width]
        continue if @map.length <= cursorY
        continue if @map[cursorY].length <= cursorX

        char = @map[cursorY][cursorX]

        tile_name = tileTypes[char].name
        # console.log tile_name

        pos = { x: cursorX, y: cursorY }
        if tile_name is 'players' or tile_name is 'treasures'
          @placeFloorTile pos
        @randomSprite char, pos

    @stage.update()


  main: ->
    @stage = new createjs.Stage("TreasureWar")

    @sprites = new Image
    @sprites.src = "sprite.png"
    @sprites.onload = @handleImageLoad


$ ->
  ui = new TreasureWarUI
  ui.main()
  players = {}

  socket = io.connect("http://#{location.hostname}:8000")
  socket.on('map', (map) ->
    # console.log map
    ui.renderMap(map)
  )
  socket.on('world state', (data) ->
    # Render players and things
    # console.log data
    if data.players.length > 0
      player = data.players[0]
      ui.randomSprite('p', {x: player.x, y: player.y})
      if (Math.random() < 0.01)
        console.log player

  )

  socket.on('connect', ->
    socket.emit("visualizer", {})
  )
