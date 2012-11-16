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

  describe "visibleTiles", ->
    beforeEach ->
      @game.map = [
        [" ", "W", " "] # x: 1, y: 0
        [" ", " ", " "]
        [" ", " ", " "]
        [" ", " ", "W"] # x: 2, y: 3
        [" ", " ", "W"] # x: 2, y: 4 Not visible
      ]

    it "should return the visible walls to the north", ->
      tiles = @game.visibleTiles x: 1, y: 1
      expect(tiles).toContain {x: 1, y: 0, type: "wall"}

    it "should return the visible walls to a range of 2", ->
      tiles = @game.visibleTiles x: 1, y: 1
      expect(tiles).toContain {x: 2, y: 3, type: "wall"}

    it "should not return tiles outside of the range of 2", ->
      tiles = @game.visibleTiles x: 1, y: 1
      expect(tiles).toNotContain {x: 2, y: 4, type: "wall"}

  describe "processAttacks", ->
    beforeEach ->
      @game.map = [
        [" ", "W", " "],
        [" ", " ", " "],
        [" ", " ", "W"]
      ]

      @player = new Player(1, x: 1, y: 1)
      @game.players.push @player
      @order = new Order(1, "attack", dir: "n")
      @order.player = @player


    it "should reject orders that target an invalid square", ->
      @game.processAttacks([@order])
      expect(@game.playerMessages[1]).toEqual [{error: "Your attack in dir n where there was no player"}]

    it "should damage a player that is in the target square", ->
      @attackee = new Player(2, x: 1, y: 0)
      @game.players.push @attackee

      @game.processAttacks([@order])
      expect(@game.playerMessages[1]).toEqual [{notice: 'You attacked unnamed coward'}]

  describe "respawnDeadPlayers", ->
    beforeEach ->
      @player = new Player(1, x: 1, y: 1)
      @game.players.push @player

    it "should send the player back to their stash", ->
      @player.health = 0
      @player.x = 0
      @player.y = 2
      @game.respawnDeadPlayers()
      expect(@player.position()).toEqual x: 1, y: 1
      expect(@game.findPlayer(1).position()).toEqual x: 1, y: 1

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
        [" ", "W", " "]
        [" ", " ", " "]
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

  describe "getTreasureAtPosition", ->
    it "returns the treasure at the specified position, or null if no treasure there", ->
      treasure_pos = {x: 3, y: 10}
      no_treasure_pos = {x: 1, y: 1}
      treasure = new Treasure(treasure_pos)
      @game.treasures.push treasure
      expect(@game.getTreasureAtPosition(treaure_pos)).toEqual treasure
      expect(@game.getTreasureAtPosition(no_treaure_pos)).toEqual null

  describe "repopTreasure", ->
    it "creates one new treasure per player, in a random position", ->
      #no players, no treasure
      @game.players = []
      expect(@game.treasures.length).toEqual 0
      game.repopTreasure()
      expect(@game.treasures.length).toEqual 0

      #2 players, 2 treasures
      @game.players = [new Player(), new Player()]
      expect(@game.treasures.length).toEqual 2
      t1 = @game.treasures[0]
      t2 = @game.treasures[1]
      expect(t1.type).toEqual 'treasure'
      expect(t2.type).toEqual 'treasure'
      #in random locations
      expect(t1.position).notToEqual t2.position

