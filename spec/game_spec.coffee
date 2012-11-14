require("../lib/models/game")
describe "Game", ->
  beforeEach ->
    @game = new Game()
    @game.map = [
      [" ", "W"],
      ["W", "W"]
    ]

  describe "spawnDungeon", ->
    it "should create a dungeon of x,y dimensions", ->
      @game.spawnDungeon(90, 50)
      # It looks like map can create maps bigger than dimension :S
      expect(@game.map.length).toBeGreaterThan 49
      expect(@game.map[0].length).toBeGreaterThan 89

  describe "spawnPlayer", ->
    it "should create a new player", ->
      @game.spawnPlayer(1)
      expect(@game.players.length).toEqual 1

    it "should create the new player on a floor tile", ->
      @game.spawnPlayer(1)
      expect(@game.isFloor @game.players[0].position()).toBeTruthy()

  describe "disconnectPlayer", ->
    it "should disconnect a player with a given id", ->
      @game.spawnPlayer(1)
      expect(@game.players.length).toEqual 1
      @game.disconnectPlayer(1)
      expect(@game.players.length).toEqual 0

  describe "validMove", ->
    beforeEach ->
      @game.map = [
        [" ", "W"],
        [" ", " "]
      ]
      @player = new Player(1, x: 0, y: 0)

    it "should return false if you'd move into a wall", ->
      expect(@game.validMove @player, "e").toBeFalsy()

    it "should return true if otherwise a valid move", ->
      expect(@game.validMove @player, "se").toBeTruthy()

  describe "surroundingTiles", ->
    beforeEach ->
      @game.map = [
        [" ", "W", " "],
        [" ", " ", " "],
        [" ", " ", "W"]
      ]

    it "should return the surrounding walls", ->
      tiles = @game.surroundingTiles x: 1, y: 1
      expect(tiles.n).toEqual "W"
      expect(tiles.se).toEqual "W"
      expect(tiles.nw).toEqual " "


  describe "payload", ->
    beforeEach ->
      @game.map = [
        [" ", "W", " "],
        [" ", " ", " "],
        [" ", " ", "W"]
      ]
      @player = new Player(1, x: 1, y: 1)
      @game.players.push @player

    it "should contain all the player info", ->
      payload = @game.tickPayloadFor(1)

  describe "setName", ->
    beforeEach ->
      @player = new Player(1, x: 1, y: 1)
      @game.players.push @player

    it "should set the name of the player", ->
      @game.setName(1, "doug")
      expect(@game.players[0].name).toBe "doug"
      expect(@game.findPlayer(1).name).toBe "doug"


  describe "findNearbyPlayers", ->
    beforeEach ->
      @player = new Player(1, x: 1, y: 1)
      @nearby = new Player(1, x: 2, y: 0) # NE
      @far = new Player(1, x: -2, y: 0)
      @game.players = [@player, @nearby, @far]

    it "should return players within one square", ->
      expect(@game.findNearbyPlayers(@player)).toEqual [@nearby]

    it "should not return players players within one square", ->
      @nearby.y = 4
      @nearby.x = 0
      expect(@game.findNearbyPlayers(@player)).toEqual []

  describe "findNearbyStashes", ->
    beforeEach ->
      @player = new Player(1, x: 1, y: 1)
      @nearby = new Player(1, x: 2, y: 0) # NE
      @nearby.y = 3 # Far!
      @far = new Player(1, x: -2, y: 0)
      @game.players = [@player, @nearby, @far]

    it "should return nearby stashes", ->
      expect(@game.findNearbyStashes(@player)[0]).toEqual {
        x: @nearby.stash.x
        y: @nearby.stash.y
        name: @nearby.name
        treasure: @nearby.stash.treasure
      }

  describe "validAttack", ->
    beforeEach ->
      @game.map = [
        [" ", "W", " "],
        [" ", " ", " "],
        [" ", " ", "W"]
      ]
      @attacker = new Player(1, x: 1, y: 1)
      @attackee = new Player(1, x: 2, y: 0) # NE
      @game.players.push @attacker
      @game.players.push @attackee

    it "should be return the attackee if a player exists at the attacking position", ->
      expect(@game.validAttack player: @attacker, dir: "ne").toEqual @attackee

    it "should not be valid if no exists at the attacking position", ->
      expect(@game.validAttack player: @attacker, dir: "n").toBeFalsy()


  describe "translatePosition", ->
    it "should move north east -y and +x", ->
      pos = {x: 3, y: 10}
      expect(@game.translatePosition(pos, "ne")).toEqual {x: 4, y: 9}
      expect(pos).toEqual {x: 3, y: 10}

