_ = require 'underscore'
item_properties = require '../mixins/item'

root.Treasure = class Treasure
  constructor: (position) ->
    @x = position.x
    @y = position.y
    _.extend(this, item_properties)

  position: -> {@x, @y}

  is_treasure: true
