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

# its a global, live with it
spriteSheet = null

class Tile
  constructor: (char) ->
    @root = @tile = new createjs.BitmapAnimation(spriteSheet)

    frames = tileTypes[char].frames
    @index = _.shuffle(frames)[0]

  draw: (x, y, index) ->
    @tile.gotoAndStop(index || @index)
    @tile.x = x * 40
    @tile.y = y * 40


class Player
  constructor: ->
    @root = @cnt = new createjs.Container
    @tile = new Tile('p')
    @cnt.addChild @tile.root
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
  constructor: ->
    @tile = new Tile('t')
    @root = @tile.root

  update: (data) ->
    @tile.draw(data.x, data.y)


class TreasureWarUI
  constructor: ->
    @players = {}
    @treasures = {}

  renderMap: () ->
    return unless @map && @spritesReady


    for cursorY in [0..(@map.length - 1)]
      for cursorX in [0..(@map[cursorY].length - 1)]
        char = @map[cursorY][cursorX]
        tile = new Tile char
        @stage.addChild tile.root
        tile.draw cursorX, cursorY


  updateTreasure: (treasure) ->
    # need to remove treasure that have been picked up
    t = @treasures[treasure.clientId] ||= new Treasure
    @stage.addChild(t.root) unless t.root.parent
    t.update(treasure)


  updatePlayer: (player) ->
    p = @players[player.clientId] ||= new Player

    @stage.addChild(p.root) unless p.root.parent

    p.update(player)


  tick: ->
    if spriteSheet?.complete
      createjs.Ticker.removeListener @
      @spritesReady = true
      @renderMap()


  main: ->
    spriteSheet = new createjs.SpriteSheet
      images: ["sprite.png"]
      animations: animations
      frames: {width: 40, height: 40}

    createjs.Ticker.addListener @

    @stage = new createjs.Stage("TreasureWar")
    createjs.Ticker.addListener @stage

  fullscreenify: ->
    canvas = $('#TreasureWar')

    $(window).on 'resize', =>
      @resize(canvas)
      false

    @resize(canvas)

  resize: (canvas) ->
    scale =
      x: (window.innerWidth - 10) / canvas.width();
      y: (window.innerHeight - 10) / canvas.height();

    # if scale.x < 1 || scale.y < 1
    #   scale = '1, 1'
    if scale.x < scale.y
      scale = scale.x + ', ' + scale.x
    else
      scale = scale.y + ', ' + scale.y

    canvas.css("transform-origin", "center top")
    canvas.css("transform", "scale(#{scale})")

$ ->
  ui = new TreasureWarUI
  ui.main()
  players = {}
  stashes = {}
  treasures = {}
  ui.fullscreenify()

  socket = io.connect("http://#{location.hostname}:8000")
  socket.on('map', (map) ->
    ui.map = map
    ui.renderMap()
  )

  socket.on('world state', (data) ->
    for treasure in data.items
      ui.updateTreasure(treasure)

    for player in data.players
      ui.updatePlayer(player)

    for id, p of players
      s = (stashes[player.clientId] ?= new Stash(ui))
      s.update(player, p.tile.index)


    $("#leaderboard").empty()
    asc_players = _(data.players).sortBy (p) -> p.score * -1
    for player in asc_players
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


