tileTypes =
  'W':
    name: 'walls'
    frames: [42..44]
  'f':
    name: 'floors'
    frames: [48]
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

# TODO: Remove globals

animations = {}

for char, data of tileTypes
  animations[char] = frames: data.frames

spriteSheet = null
clouds = []
ui = null

TILE_WIDTH = 40
TILE_HEIGHT = 40

class Tile
  constructor: (char) ->
    @root = @tile = new createjs.BitmapAnimation(spriteSheet)

    frames = tileTypes[char].frames
    @index = _.shuffle(frames)[0]

  draw: (x, y, index) ->
    @tile.gotoAndStop(index || @index)
    @tile.x = x * TILE_WIDTH * ui.scale + ui.position.x
    @tile.y = y * TILE_HEIGHT * ui.scale + ui.position.y
    @tile.scaleX = ui.scale
    @tile.scaleY = ui.scale

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

    @tile.root.gotoAndStop(index)
    @cnt.x = data.x * TILE_WIDTH * ui.scale + ui.position.x
    @cnt.y = data.y * TILE_HEIGHT * ui.scale + ui.position.y
    @cnt.scaleX = ui.scale
    @cnt.scaleY = ui.scale

    data.health = 100

    @bar.gotoAndStop l = healthBar[Math.floor(data.health / healthChunk)]
    @bar.scaleX = 1.5
    @bar.scaleY = 1.5

    @name.text = data.name
    @age = 0

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
    @cnt.x = data.stash.x * TILE_WIDTH * ui.scale + ui.position.x
    @cnt.y = data.stash.y * TILE_HEIGHT * ui.scale + ui.position.y
    @cnt.scaleX = ui.scale
    @cnt.scaleY = ui.scale
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
    @unscaledSize =
    @mapContainer =
    @canvas = canvas
    @mapDimensions =
      x: 0
      y: 0

  renderMap: () ->
    return unless @map && spriteSheet?.complete

    for cursorY in [0..(@map.length - 1)]
      for cursorX in [0..(@map[cursorY].length - 1)]
        char = @map[cursorY][cursorX]
        continue if char == ' '

        if cursorX >= @mapDimensions.x
          @mapDimensions.x = cursorX + 1
        if cursorY >= @mapDimensions.y
          @mapDimensions.y = cursorY + 1

    console.log @mapDimensions

    @unscaledSize.x = @mapDimensions.x * TILE_WIDTH
    @unscaledSize.y = @mapDimensions.y * TILE_HEIGHT
    @calculateScale()
    @stage.removeChild @mapContainer if @mapContainer
    @mapContainer = new createjs.Container

    for cursorY in [0..(@map.length - 1)]
      for cursorX in [0..(@map[cursorY].length - 1)]
        char = @map[cursorY][cursorX]
        continue if char == ' '

        tile = new Tile char
        tile.draw cursorX, cursorY
        @mapContainer.addChild tile.root

    @mapContainer.cache 0, 0, @canvas.width(), @canvas.height(), 1
    @stage.addChild @mapContainer

  renderClouds: () ->
    return unless clouds.length > 0

    @stage.addChildAt @skyBox, 0

    for idx in [0..clouds.length - 1]
      clouds[idx].x += (idx + 1 ) / 3 + 1

      if clouds[idx].x > @canvas.width()
        @resetCloud(clouds[idx])

      @stage.addChildAt clouds[idx], 1


  addChild: (child) ->
    @stage.addChild child.root
    child

  removeChild: (child) ->
    @stage.removeChild child.root
    child

  resetCloud: (cloud) ->
    cloud.x = -cloud.image.width * 2
    cloud.y = Math.floor(Math.random() * @canvas.height()) - cloud.image.height
    cloud.alpha = Math.random() * 0.5 + 0.4
    cloud.scaleX = Math.random() * 0.4 + 0.8
    cloud.scaleY = 1

  updateTreasure: (treasure) ->
    # need to remove treasure that have been picked up
    t = @treasures[treasure.clientId] ||= @addChild(new Treasure)
    t.update(treasure)


  updatePlayer: (data) ->
    p = @players[data.clientId] ||= @addChild(new Player)
    p.update(data)

    s = @stashes[data.clientId] ||= @addChild(new Stash(p))
    s.update(data)

  reapPlayersNotUpdated: (clientIds)->
    for clientId, player of @players
      if clientId not in clientIds
        @removeChild(@players[clientId])
        @removeChild(@stashes[clientId])
        delete @players[clientId]
        delete @stashes[clientId]

  tick: ->
    @renderClouds()


  main: ->
    spriteSheet = new createjs.SpriteSheet
      images: ["sprite.png"]
      animations: animations
      frames: {width: 40, height: 40}
    @cloud = new createjs.Bitmap 'cloud.png'

    @fullscreenify()
    @stage = new createjs.Stage(@canvas[0])
    @initializeClouds()
    @redraw()
    createjs.Ticker.setFPS 20
    createjs.Ticker.addListener @stage
    createjs.Ticker.addListener @

  initializeClouds: ->
    for i in [1..NUM_CLOUDS]
      newCloud =  @cloud.clone()
      @resetCloud(newCloud)
      newCloud.x = Math.floor(Math.random() * @canvas.width() * 0.6) - newCloud.image.width
      clouds.push newCloud

  fullscreenify: ->
    $(window).on 'resize', =>
      @resizeCanvas()
      false

    @resizeCanvas()

  renderSkyBox: ->
    skyBoxGradient = new createjs.Graphics
    skyBoxGradient.beginLinearGradientFill(["#046","#68C"], [0.7, 1], 0, 0, 0, @canvas.height()).drawRect(0, 0, @canvas.width(), @canvas.height())
    @skyBox = new createjs.Shape(skyBoxGradient)
    @skyBox.x = 0
    @skyBox.y = 0
    @stage.addChildAt @skyBox, 0

  redraw: ->
    return unless @stage
    @stage.removeAllChildren()
    @renderMap()
    @renderSkyBox()
    @renderClouds()
    for clientId, player of @players
      @addChild(player)
    for clientId, stash of @stashes
      @addChild(stash)

  resizeCanvas: ->
    # Using .css() here merely stretches the canvas, it doesn't resize it.
    @canvas[0].width = window.innerWidth
    @canvas[0].height = window.innerHeight
    @redraw()

  calculateScale: ->  
    scale =
      x: @canvas.width() / @unscaledSize.x
      y: @canvas.height() / @unscaledSize.y

    @position = 
      x: Math.floor((@canvas.width() - @unscaledSize.x * scale.y) / 2)
      y: Math.floor((@canvas.height() - @unscaledSize.y * scale.x) / 2)

    if scale.x < scale.y
      @scale = scale.x
      @position.x = 0
    else
      @scale = scale.y
      @position.y = 0

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
  console.log('herp')
  ui = new TreasureWarUI $('#TreasureWar')
  ui.main()
  leaderboard = new Leaderboard($("#leaderboard"))

  socket = io.connect("http://#{location.hostname}:#{location.port}")

  socket.on('connect', ->
    socket.emit("visualizer", {})
  )

  socket.on('map', (map) ->
    ui.map = map
    console.log('map');
    ui.renderMap()
  )

  socket.on('world state', (data) ->
    for treasure in data.items
      ui.updateTreasure(treasure)

    updatedClientIds = []
    for player in data.players
      ui.updatePlayer(player)
      updatedClientIds.push player.clientId

    ui.reapPlayersNotUpdated(updatedClientIds)

    leaderboard.update(data.players)

    # if data.events
    #   for event in data.events
    #     if event == "attack"
    #       pewIndex = parseInt(Math.random() * 5) + 1
    #       window.clips["pew#{pewIndex}"].play()
    #     else if event == "kill"
    #       window.clips["bugle"].play()
  )


  # audioClips = ["pew1", "pew2", "pew3", "pew4", "pew5", "bugle"]
  # window.clips = {}

  # for clip in audioClips
  #   window.clips[clip] = new buzz.sound("/sounds/#{clip}", formats: ["mp3"])
