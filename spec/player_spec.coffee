require("../lib/models/player")

describe "Player", ->
  beforeEach ->
    @player = new Player(1, x: 3, y: 4)

  describe "tickPayload", ->
    it "should contain the players vitals", ->
      expect(@player.tickPayload()).toEqual {
        name: @player.name
        health: @player.health
        score: @player.score
        carrying_treasure: @player.carrying_treasure
        stash:
          x: 3
          y: 4
          treasure: []
        position:
          x: 3
          y: 4

      }

  describe "takeTreasure", ->
    it "puts treasure in hand if not carrying anything", ->
      #true when nothing in hand
      @player.item_in_hand = null
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.takeTreasure(treasure)).toEqual true

      #false when carrying something
      @player.item_in_hand = new Treasure({x: 1, y: 2})
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.takeTreasure(treasure)).toEqual false

  describe "isCarryingTreasure", ->
    it "returns true or false depending on if player is carrying treausre", ->
      #true when nothing in hand
      @player.item_in_hand = null
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.takeTreasure(treasure)).toEqual true

      #false when carrying something
      @player.item_in_hand = new Treasure({x: 1, y: 2})
      treasure = new Treasure({x: 0, y: 0})
      expect(@player.takeTreasure(treasure)).toEqual false
      
