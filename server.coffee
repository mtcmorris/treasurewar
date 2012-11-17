sys = require('sys')
require('./lib/models/game')
require('./lib/models/order')
_ = require('underscore')

#----------------------------------------
# Config Settings
SERVER_PORT = 8000
#----------------------------------------

game = new Game()
game.spawnDungeon(100, 100)
sys.puts game.mapToString()

visualizers = []

io = require('socket.io').listen(SERVER_PORT)

tickGame = ->
  # console.log "Game tick"
  game.tick()
  # Send updated world state to each player
  for client in io.sockets.clients()
    if isVisualizer(client)
      client.emit 'world state', game.visualizerTickPayload()
    else
      client.emit 'tick', game.tickPayloadFor(client.id)

  io.sockets.emit 'message', { message: "Hello everyone!" }
setInterval tickGame, 1000

isVisualizer = (socket) ->
  _(visualizers).contains socket.id

validForVisualizer = (ip) ->
  ip == "127.0.0.1"

io.sockets.on('connection', (socket) ->
  console.log "Spawning player for #{socket.id}"
  game.spawnPlayer(socket.id)

  socket.on("set name", (player_name) ->
    game.setName(socket.id, player_name) unless isVisualizer(socket)
  )

  socket.on("visualizer", (data) ->
    if validForVisualizer(socket.handshake.address.address)
      visualizers.push socket.id
      game.disconnectPlayer(socket.id)
      socket.emit 'map', game.map
  )

  socket.on("move", (data) ->
    game.registerOrder(new Order(socket.id, "move", data)) unless isVisualizer(socket)
  )

  socket.on("attack", (data) ->
    game.registerOrder(new Order(socket.id, "attack", data)) unless isVisualizer(socket)
  )

  socket.on("throw", (data) ->
    game.registerOrder(new Order(socket.id, "throw", data)) unless isVisualizer(socket)
  )

  socket.on("pick up", (data) ->
    game.registerOrder(new Order(socket.id, "pick up", data)) unless isVisualizer(socket)
  )

  socket.on("disconnect",  ->
    visualizers = _(visualizers).reject (id) -> id == socket.id
    game.disconnectPlayer(socket.id)
  )
)
