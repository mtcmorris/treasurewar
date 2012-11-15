
root.Player = class Player
  constructor: (clientId, position) ->
    @clientId = clientId
    @name = "unnamed coward"
    @health = 100
    @x = position.x
    @y = position.y
    @kills = 0
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

  calcScore: ->
    @score = @kills + @stash.treasure * 10

  anonPayload: ->
    name: @name
    health: @health
    score: @score
    carrying_treasure: @carrying_treasure
    position: @position()

  respawn: ->
    @health = 100
    @x = @stash.x
    @y = @stash.y