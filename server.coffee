sys = require('sys')
require('./lib/models/game')
require('./lib/models/order')


game = new Game()
game.spawnDungeon(100, 100)
sys.puts game.mapToString()

io = require('socket.io').listen(3001);

tickGame = ->
  # console.log "Game tick"
  game.tick()
  # Send updated world state to each player
  for client in io.sockets.clients()
    client.emit 'tick', game.tickPayloadFor(client.id)

  io.sockets.emit 'message', { message: "Hello everyone!" }
setInterval tickGame, 2000

io.sockets.on('connection', (socket) ->
  console.log "Spawning player for #{socket.id}"
  game.spawnPlayer(socket.id)

  socket.on("set name", (player_name) ->
    console.log "set name: #{socket.id} #{player_name}"
    game.setName(socket.id, player_name)
  )

  socket.on("move", (data) ->
    game.registerOrder(new Order(socket.id, "move", data))
  )

  socket.on("attack", (data) ->
    game.registerOrder(new Order(socket.id, "attack", data))
  )

  socket.on("throw", (data) ->
    game.registerOrder(new Order(socket.id, "throw", data))
  )

  socket.on("pick up", (data) ->
    game.registerOrder(new Order(socket.id, "pick up", data))
  )

  socket.on("disconnect",  ->
    game.disconnectPlayer(socket.id)
  )

  socket.on('my other event', (data) ->
    console.log(data)
  )
)
