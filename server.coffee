sys = require('sys')
http = require('http')
require('./lib/models/game')
server = http.createServer()

WebSocket = require('faye-websocket')



game = new Game()
game.spawnDungeon(100, 100)
sys.puts game.mapToString()

# tickGame = ->
#   # console.log "Game tick"
#   # Send messages to each player
#   setTimeout tickGame, 2000
# setTimeout tickGame, 2000

server.addListener('upgrade', (request, socket, head) ->
  ws = new WebSocket(request, socket, head)

  ws.onconnect = ->
    console.log "LOL"

  ws.onmessage = (event) ->
    console.log "SUPPP"
    console.log event.currentTarget.request
    ws.send(event.data)

  ws.onclose = (event) ->
    console.log('close', event.code, event.reason)
    ws = null;
)

server.listen(3001)