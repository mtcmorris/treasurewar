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
          position: @player.stash.position #ghetto fixme todo
          setPosition: @player.stash.setPosition #ghetto fixme todo
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

      it 'tells us it dropped the item and deposited it', ->
        expect(@drop_result.did_deposit).toEqual true
        expect(@drop_result.dropped_item).toEqual @item

      it 'deposits treasure', ->
        expect(@deposit_spy).toHaveBeenCalledWith(@item)

    describe 'when dropping on non stash', ->
      beforeEach ->
        @item = new Treasure(@player.position())
        @player.pickup(@item)
        @player.x = @player.stash.x + 10
        @player.y = @player.stash.y + 10
        @drop_result = @player.dropHeldItem()

      it 'tells us it dropped the item and it did not deposit', ->
        expect(@drop_result.did_deposit).toBeUndefined()
        expect(@drop_result.dropped_item).toEqual @item

    describe 'when holding nothing', ->
      it 'tells us it didnt drop anything', ->
        @player.item_in_hand = null
        @drop_result = @player.dropHeldItem()
        expect(@drop_result.dropped_item).toEqual null

  describe "#isCarryingTreasure", ->
    it 'returns true when player is carrying treasure', ->
      treasure = new Treasure(1, 2)
      @player.item_in_hand = treasure
      expect(@player.isCarryingTreasure()).toEqual true

  describe "#respawn", ->
    it 'restores the player health to 100', ->
      @player.health = 0
      @player.respawn()
      expect(@player.health).toEqual 100

    it 'sets the player back to their stash', ->
      @player = new Player(1, x: 3, y: 4)
      @player.setPosition(10,12)
      @player.respawn()
      expect(@player.position()).toEqual {x: 3, y: 4}

    it 'removes whatever they were holding', ->
      @player.item_in_hand = new Treasure({x: 1, y: 2})
      @player.respawn()
      expect(@player.item_in_hand).toBeNull

