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

  dropHeldItem: ->
    return false unless @item_in_hand
    item = @item_in_hand
    @item_in_hand = null
    if item.type == 'treasure' && item.position().x == @position().x && item.position().y == @position().y
      @depositTreasure(item)
    return item

  depositTreasure: (item) ->
    @stash.treasures.push treasure

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

