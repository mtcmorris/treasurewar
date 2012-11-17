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
    @tile = new Tile('p')
    @root = @tile.root

  update: (data)->
    @tile.draw(data.stash.x, data.stash.y, @player.baseIndex + 12)


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
    @stashes = {}


  renderMap: () ->
    return unless @map && @spritesReady

    for cursorY in [0..(@map.length - 1)]
      for cursorX in [0..(@map[cursorY].length - 1)]
        char = @map[cursorY][cursorX]
        tile = new Tile char
        @stage.addChild tile.root
        tile.draw cursorX, cursorY


  addChild: (child) ->
    @stage.addChild child.root
    child


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
      x: (window.innerWidth - 10) / canvas.width()
      y: (window.innerHeight - 10) / canvas.height()

    if scale.x < scale.y
      scale = scale.x + ', ' + scale.x
    else
      scale = scale.y + ', ' + scale.y

    canvas.css("transform-origin", "left top")
    canvas.css("transform", "scale(#{scale})")

class Leaderboard
  constructor: (@el) ->
  update: (players) ->
    asc_players = _(players).sortBy (p) -> p.score * -1
    list = @el.find(".players")
    list.empty()
    if asc_players.length == 0
      list.append """<div class='empty'>No players :(</div>"""
    else
      for p in asc_players
        @makePlayerEl(p).appendTo(list)
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
  ui = new TreasureWarUI
  ui.main()
  ui.fullscreenify()
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

    if data.events
      for event in data.events
        if event == "attack"
          pewIndex = parseInt(Math.random() * 5) + 1
          window.clips["pew#{pewIndex}"].play()
        else if event == "kill"
          # console.log "LOL"
          window.clips["bugle"].play()
  )

  socket.on('connect', ->
    socket.emit("visualizer", {})
  )

  audioClips = ["pew1", "pew2", "pew3", "pew4", "pew5", "bugle"]
  window.clips = {}

  for clip in audioClips
    window.clips[clip] = new buzz.sound("/sounds/#{clip}", formats: ["mp3"])
