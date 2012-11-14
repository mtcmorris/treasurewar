require("../lib/models/game")
describe "Game", ->
  beforeEach ->
    @game = new Game()

  describe "spawnDungeon", ->
    it "should create a dungeon of x,y dimensions", ->
      @game.spawnDungeon(90, 50)
      # It looks like map can create maps bigger than dimension :S
      expect(@game.map.length).toBeGreaterThan 49
      expect(@game.map[0].length).toBeGreaterThan 89

  describe "spawnPlayer", ->
    beforeEach ->
      @game.map = [
        [" ", "W"],
        ["W", "W"]
      ]

    it "should create a new player", ->
      @game.spawnPlayer()
      expect(@game.players.length).toEqual 1

    it "should create the new player on a floor tile", ->
      @game.spawnPlayer()
      expect(@game.isFloor @game.players[0].position()).toBeTruthy()

  describe "validMove", ->
    beforeEach ->
      @game.map = [
        [" ", "W"],
        [" ", " "]
      ]
      @player = new Player(x: 0, y: 0)

    it "should return false if you'd move into a wall", ->
      expect(@game.validMove @player, "e").toBeFalsy()

    it "should return true if otherwise a valid move", ->
      expect(@game.validMove @player, "se").toBeTruthy()

  describe "translatePosition", ->
    it "should move north east -y and +x", ->
      pos = {x: 3, y: 10}
      expect(@game.translatePosition(pos, "ne")).toEqual {x: 4, y: 9}
      expect(pos).toEqual {x: 3, y: 10}

