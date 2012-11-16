root.Treasure = class Treasure
  constructor: (@position) ->
    @x = @position.x
    @y = @position.y

  position: -> {@x, @y}

  type: 'treasure'
