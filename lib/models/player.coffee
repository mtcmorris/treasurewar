_ = require 'underscore'
positioned_properties = require('../mixins/positioned').positioned_properties

root.Player = class Player
  constructor: (clientId, position) ->
    @clientId = clientId
    @name = "unnamed coward"
    @health = 100
    @x = position.x
    @y = position.y
    @kills = 0
    @score = 0
    @item_in_hand = null
    @stash = {
      x: position.x
      y: position.y
      treasures: []
    }
    _.extend(@stash, positioned_properties)
    _.extend(this, positioned_properties)

  pickup: (item) ->
    if @item_in_hand
      return false
    else
      @item_in_hand = item
      true

  # Drop the item currently in hand.
  # Returns false if there is no item to drop.
  # Also returns false if dropping the item consumes it,
  # i.e. it should be not placed on the map.
  dropHeldItem: ->
    return {dropped_item: null} unless @item_in_hand
    [dropped_item, @item_in_hand] = [@item_in_hand, null]
    if dropped_item.is_treasure && @x == @stash.x && @y == @stash.y
      @depositTreasure(dropped_item)
      return {dropped_item, did_deposit: true}
    else
      return {dropped_item}

  depositTreasure: (item) ->
    @stash.treasures.push item

  isCarryingTreasure: -> @item_in_hand?.type == 'treasure'

  tickPayload: ->
    name: @name
    health: @health
    score: @score
    carrying_treasure: @isCarryingTreasure()
    item_in_hand: @item_in_hand
    stash: @stash
    position: @position()

  calcScore: ->
    @score = @kills + @stash.treasures.length * 10

  anonPayload: ->
    name: @name
    health: @health
    score: @score
    item_in_hand: @item_in_hand
    carrying_treasure: @isCarryingTreasure()
    type: 'player'
    position: @position()

  respawn: ->
    @health = 100
    @x = @stash.x
    @y = @stash.y

