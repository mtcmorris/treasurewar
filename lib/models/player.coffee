
root.Player = class Player
  constructor: (clientId, position) ->
    @clientId = clientId
    @name = "unnamed coward"
    @health = 100
    @x = position.x
    @y = position.y
    @score = 0
    @carrying_treasure = false
    @stash = {
      x: position.x
      y: position.y
      treasure: 0
    }

  position: ->
    {x: @x, y: @y }

  tickPayload: ->
    name: @name
    health: @health
    score: @score
    carrying_treasure: @carrying_treasure
    stash_location: @stash
    position: @position()
