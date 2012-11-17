_ = require 'underscore'
item_properties = require('../mixins/item').item_properties
positioned_properties = require('../mixins/positioned').positioned_properties

root.Treasure = class Treasure
  constructor: (position) ->
    _.extend(this, item_properties)
    _.extend(this, positioned_properties)
    @x = position.x
    @y = position.y
    @is_treasure = true

  anonPayload: -> {@x, @y, type: 'treasure', @name}




