sys = require('sys')
require('./lib/models/game')


game = new Game()
game.spawnDungeon(100, 100)
sys.puts game.mapToString()

io = require('socket.io').listen(3001);

tickGame = ->
  # console.log "Game tick"
  # Send messages to each player
  for client in io.sockets.clients()
    client.emit 'message', { message: "Hey #{Math.random()}!" }
  io.sockets.emit 'message', { message: "Hello everyone!" }
setInterval tickGame, 2000

io.sockets.on('connection', (socket) ->
  console.log "Spawning player for #{socket.id}"
  game.spawnPlayer(socket.id)
  socket.emit('news', { hello: 'world' })
  socket.emit('message', "Sup foo")
  socket.on("disconnect",  ->
    game.disconnectPlayer(socket.id)
  )
  socket.on('my other event', (data) ->
    console.log(data)
  )
)
