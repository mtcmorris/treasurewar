require("../lib/models/player")
require("../lib/models/treasure")

describe "Player", ->
  beforeEach ->
    @player = new Player(1, x: 3, y: 4)

  describe "tickPayload", ->
    it "should contain the players vitals", ->
      expect(@player.tickPayload()).toEqual {
        name: @player.name
        health: @player.health
        score: @player.score
        carrying_treasure: @player.isCarryingTreasure()
        item_in_hand: @player.item_in_hand
        stash:
          x: 3
          y: 4
          treasures: []
          position: @player.stash.position #ghetto
        position:
          x: 3
          y: 4

      }

  describe "calcScore", ->
    beforeEach ->
      @player.stash.treasures = [new Treasure(@player.position()), new Treasure(@player.position())]
      @player.kills = 3
      @player.calcScore()

    it "should have a score with kills + treasure", ->
      expect(@player.score).toEqual 23

  describe "#pickup(item)", ->
    beforeEach ->
      @item = new Treasure(@player.position())
      @player.pickup(@item)

    it "puts treasure in hand if not carrying anything", ->
      #true when nothing in hand
      @player.item_in_hand = null
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.pickup(treasure)).toEqual true

      #false when carrying something
      @player.item_in_hand = new Treasure({x: 1, y: 2})
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.pickup(treasure)).toEqual false

  describe "#dropHeldItem(item)", ->
    it 'removes the item from hand', ->
      @item = new Treasure(@player.position())
      @player.pickup(@item)
      expect(@player.item_in_hand).toEqual @item
      @player.dropHeldItem()
      expect(@player.item_in_hand).toEqual null

    describe 'when dropping treasure on stash', ->
      beforeEach ->
        @item = new Treasure(@player.position())
        @player.pickup(@item)
        @player.x = @player.stash.x
        @player.y = @player.stash.y
        @deposit_spy = spyOn(@player, 'depositTreasure')
        @drop_result = @player.dropHeldItem()

      it 'returns false', ->
        expect(@drop_result).toEqual false

      it 'deposits treasure', ->
        expect(@deposit_spy).toHaveBeenCalledWith(@item)

    describe 'when dropping on non stash', ->
      beforeEach ->
        @item = new Treasure(@player.position())
        @player.pickup(@item)
        @player.x = @player.stash.x + 10
        @player.y = @player.stash.y + 10
        @drop_result = @player.dropHeldItem()

      it 'returns true', ->
        expect(@drop_result).toEqual true

    describe 'when holding nothing', ->
      it 'returns false', ->
        @player.item_in_hand = null
        expect(@player.dropHeldItem()).toEqual false
