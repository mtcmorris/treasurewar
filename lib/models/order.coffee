root.Order = class Order
  constructor: (clientId, command, payload) ->
    @clientId = clientId
    @command = command
    @payload = payload