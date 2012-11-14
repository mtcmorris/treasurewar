require("../lib/models/player")

describe "Player", ->
  describe "tickPayload", ->
    beforeEach ->
      @player = new Player(1, x: 3, y: 4)

    it "should contain the players vitals", ->
      expect(@player.tickPayload()).toEqual {
        name: @player.name
        health: @player.health
        score: @player.score
        carrying_treasure: @player.carrying_treasure
        stash_location:
          x: 3
          y: 4
          treasure: 0
        position:
          x: 3
          y: 4

      }