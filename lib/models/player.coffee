
root.Player = class Player
  constructor: (position) ->
    @name = "unnamed coward"
    @health = 100
    @x = position.x
    @y = position.y
    @stash = {
      x: position.x
      y: position.y
      contents: {
        treasure: 0
      }
    }

  position: ->
    {x: @x, y: @y }