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

healthBar = [
  35
  34
  33
  32
  31
  30
]
healthChunk = 100/healthBar.length

animations = {}

for char, data of tileTypes
  animations[char] = frames: data.frames

# its a global, live with it
spriteSheet = null
clouds = []

TILE_WIDTH = 40
TILE_HEIGHT = 40

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

    @name = new createjs.Text "Fred", "bold 20px Arial", '#0f0'
    @name.textAlign = 'center'
    @name.textBaseline = 'bottom'
    @name.x += 20
    @cnt.addChild @name

    @bar = new createjs.BitmapAnimation(spriteSheet)
    @bar.gotoAndStop healthBar[healthBar.length-1]
    @cnt.addChild @bar


  update: (data) ->
    index = @baseIndex
    if data.health < 50
      index += 12
    if data.carry_treasure
      index += 6

    @tile.root.gotoAndStop(index || @index)
    @cnt.x = data.x * 40
    @cnt.y = data.y * 40

    data.health = 100

    @bar.gotoAndStop l = healthBar[Math.floor(data.health / healthChunk)]
    @bar.scaleX = 1.5
    @bar.scaleY = 1.5

    @name.text = data.name

class Stash

  constructor: (@player) ->
    @root = @cnt = new createjs.Container

    @tile = new Tile('p')

    @cnt.addChild @tile.root

    @name = new createjs.Text "Fred's Stash", "bold 20px Arial", '#ff0'
    @name.textAlign = 'center'
    @name.textBaseline = 'bottom'
    @name.x += 20
    @cnt.addChild @name

  update: (data)->
    @tile.root.gotoAndStop(@player.baseIndex + 12)

    @cnt.x = data.stash.x * TILE_WIDTH
    @cnt.y = data.stash.y * TILE_HEIGHT
    @name.text =  @player.name.text + "'s Stash"


class Treasure

  constructor: ->
    @tile = new Tile('t')
    @root = @tile.root

  update: (data) ->
    @tile.draw(data.x, data.y)


class TreasureWarUI
  NUM_CLOUDS = 8
  LEADERBOARD_WIDTH = 240

  constructor: (canvas) ->
    @players = {}
    @treasures = {}
    @stashes = {}
    @mapContainer = new createjs.Container
    @canvas = canvas
    @mapDimensions =
      x: 0
      y: 0

  renderMap: () ->
    return unless @map && @spritesReady

    for cursorY in [0..(@map.length - 1)]
      for cursorX in [0..(@map[cursorY].length - 1)]
        char = @map[cursorY][cursorX]
        continue if char == ' '

        if cursorX >= @mapDimensions.x
          @mapDimensions.x = cursorX + 1
        if cursorY >= @mapDimensions.y
          @mapDimensions.y = cursorY + 1
      
        tile = new Tile char
        @mapContainer.addChild tile.root
        tile.draw cursorX, cursorY

    @mapContainer.updateCache() if @mapContainer.cacheCanvas
    @stage.addChild @mapContainer

  renderClouds: () ->
    return unless clouds.length > 0

    @stage.addChildAt @skyBox, 0

    for idx in [0..clouds.length - 1]
      clouds[idx].x += (idx + 1) / 2

      if clouds[idx].x > @canvas.width()
        @resetCloud(clouds[idx])

      @stage.addChildAt clouds[idx], 1


  addChild: (child) ->
    @stage.addChild child.root
    child

  resetCloud: (cloud) ->
    cloud.x = -cloud.image.width * 2
    cloud.y = Math.floor(Math.random() * @canvas.height()) - cloud.image.height
    cloud.alpha = Math.random() * 0.5 + 0.4
    cloud.scaleX = Math.random() * 0.8 + 1.6
    cloud.scaleY = 2

  updateTreasure: (treasure) ->
    # need to remove treasure that have been picked up
    t = @treasures[treasure.clientId] ||= @addChild(new Treasure)
    t.update(treasure)


  updatePlayer: (data) ->
    p = @players[data.clientId] ||= @addChild(new Player)
    p.update(data)

    s = @stashes[data.clientId] ||= @addChild(new Stash(p))
    s.update(data)

  tick: ->
    if spriteSheet?.complete && @map && !@spritesReady
      # createjs.Ticker.removeListener @
      @spritesReady = true
      @renderMap()
      @canvas[0].width = @mapDimensions.x * TILE_WIDTH
      @canvas[0].height = @mapDimensions.y * TILE_HEIGHT 
      @mapContainer.cache 0, 0, @canvas.width(), @canvas.height(), 1

      $(window).on 'resize', =>
        @resizeCanvas()
        false
      @resizeCanvas()

    if @map && @cloud.image.complete && clouds.length == 0
      for i in [1..NUM_CLOUDS]
        newCloud =  @cloud.clone()
        @resetCloud(newCloud)
        newCloud.x = Math.floor(Math.random() * @canvas.width()) - newCloud.image.width
        clouds.push newCloud

      skyBoxGradient = new createjs.Graphics
      skyBoxGradient.beginLinearGradientFill(["#046","#68C"], [0.7, 1], 0, 0, 0, @canvas.height()).drawRect(0, 0, @canvas.width(), @canvas.height())
      @skyBox = new createjs.Shape(skyBoxGradient)
      @skyBox.x = 0
      @skyBox.y = 0


    @renderClouds()


  main: ->
    spriteSheet = new createjs.SpriteSheet
      images: ["sprite.png"]
      animations: animations
      frames: {width: 40, height: 40}

    @cloud = new createjs.Bitmap 'cloud.png'

    createjs.Ticker.addListener @
    createjs.Ticker.setFPS(20);

    @stage = new createjs.Stage(@canvas[0])
    createjs.Ticker.addListener @stage

  fullscreenify: ->
    $(window).on 'resize', =>
      @resizeCanvas()
      false

    @resizeCanvas()

  resizeCanvas: ->

    windowWidth = window.innerWidth - LEADERBOARD_WIDTH
    scale =
      x: windowWidth / @canvas.width()
      y: window.innerHeight / @canvas.height()

    position = 
      x: (windowWidth - @canvas.width() * scale.y) / 2 + LEADERBOARD_WIDTH
      y: (window.innerHeight - @canvas.height() * scale.x) / 2

    if scale.x < scale.y
      scale = scale.x + ', ' + scale.x
      @canvas.css("top", position.y)
      @canvas.css("left", LEADERBOARD_WIDTH) 
    else
      scale = scale.y + ', ' + scale.y
      @canvas.css("left", position.x)
      @canvas.css("top", 0) 

    @canvas.css("transform-origin", "left top")
    @canvas.css("transform", "scale(#{scale})")

class Leaderboard
  constructor: (@el) ->
  update: (players) ->
    asc_players = _(players).sortBy (p) -> p.score * -1
    list = @el.find(".players")
    list.empty()
    if asc_players.length == 0
      list.append """<div class='empty'>No players :(</div>"""
    else
      nonScoring = 0
      for p in asc_players
        if p.score > 0
          @makePlayerEl(p).appendTo(list)
        else 
          nonScoring += 1
      if nonScoring > 0
        $("""<div class=name>#{nonScoring} other player(s)</div>""").appendTo(list)

  makePlayerEl: (player) ->
    $("""<div class='player avatar-#{@avatar(player)}'>
      <div class='name'>#{player.name}</div>
      <div class='score'>#{player.score}</div>
    </div>
    """)
  avatar: (player) ->
    if player.name
      spriteLength = 6
      firstCharCode = player.name.charCodeAt(0) or 0
      firstCharCode % spriteLength
    else
      0

$ ->
  ui = new TreasureWarUI $('#TreasureWar')
  ui.main()
  leaderboard = new Leaderboard($("#leaderboard"))

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

    leaderboard.update(data.players)

    # if data.events
    #   for event in data.events
    #     if event == "attack"
    #       pewIndex = parseInt(Math.random() * 5) + 1
    #       window.clips["pew#{pewIndex}"].play()
    #     else if event == "kill"
    #       window.clips["bugle"].play()
  )

  socket.on('connect', ->
    socket.emit("visualizer", {})
  )

  # audioClips = ["pew1", "pew2", "pew3", "pew4", "pew5", "bugle"]
  # window.clips = {}

  # for clip in audioClips
  #   window.clips[clip] = new buzz.sound("/sounds/#{clip}", formats: ["mp3"])
