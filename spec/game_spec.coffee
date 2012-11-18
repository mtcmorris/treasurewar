_ = require('underscore')
require("../lib/models/game")
describe "Game", ->
  beforeEach ->
    @game = new Game()
    @game.options.player_vision_distance = 2
    @game.map = [
      ["W", "W", "f"]
      ["W", "f", "f"]
      ["W", "f", "f"]
    ]
    @game.mapX = 3
    @game.mapY = 3

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

  describe "processMoves", ->
    beforeEach ->
      @player   = new Player(1, x: 1, y: 1)
      @order    = new Order(1, "attack", dir: "n")
      @order.player = @player

      @moveSpy     = spyOn(@game, 'movePlayer')
      @messageSpy  = spyOn(@game, 'messageClient')

    describe "with a valid move", ->
      beforeEach ->
        spyOn(@game, 'validMove').andReturn(true)
        @game.processMoves([@order])

      it 'should move the player', ->
        expect(@moveSpy).toHaveBeenCalledWith(@order.player, 'n')

      it 'should set last_update to current time', ->
        expect(@player.last_update).toBeGreaterThan(+new Date - 1000)

    describe "with an invalid move", ->
      beforeEach ->
        spyOn(@game, 'validMove').andReturn(false)
        @player.last_update = 500
        @game.processMoves([@order])

      it 'should not move the player', ->
        expect(@moveSpy).not.toHaveBeenCalled()

      it 'should not update last_update', ->
        expect(@player.last_update).toEqual(500)

    describe "errors", ->
      beforeEach ->
        @order.player = null

      describe "when player disconnects", ->
        it "should not assplode", ->
          error = null
          try
            @game.processMoves([@order])
          catch e
            error = e
          expect(error).toBeNull()

  describe "validMove", ->
    beforeEach ->
      @game.map = [
        ["f", "W"],
        ["f", "f"]
      ]
      @player = new Player(1, x: 0, y: 0)

    it "should return false if you'd move into a wall", ->
      expect(@game.validMove @player, "e").toBeFalsy()

    it "returns false if you'd move into a player", ->
      @player.setPosition(0, 0)
      @player2 = new Player(2, {x: @player.x, y: @player.y + 1})
      @game.players.push @player2
      # player2 is below player
      # so, player cannot move south
      expect(@game.validMove @player, "s").toBeFalsy()

    it "should return true if otherwise a valid move", ->
      expect(@game.validMove @player, "se").toBeTruthy()

  describe "#visibleTiles(position)", ->
    beforeEach ->
      @game.map = [
        ["f", "W", "f"] # x: 1, y: 0
        ["f", "f", "f"]
        ["f", "f", "f"]
        ["f", "f", "W"] # x: 2, y: 3
        ["f", "f", "W"] # x: 2, y: 4 Not visible
      ]
      @treasure_x0y1 = new Treasure(x: 0, y: 1) 
      @game.items.push @treasure_x0y1

    it "should return the visible walls to the north", ->
      tiles = @game.visibleTiles x: 1, y: 1
      expect(tiles).toContain {x: 1, y: 0, type: "wall"}

    it "should return the visible walls to a range of 2", ->
      tiles = @game.visibleTiles x: 1, y: 1
      expect(tiles).toContain {x: 2, y: 3, type: "wall"}

    it "should not return tiles outside of the range of 2", ->
      tiles = @game.visibleTiles x: 1, y: 1
      expect(tiles).toNotContain {x: 2, y: 4, type: "wall"}

    it "returns all treasure visible", ->
      tiles = @game.visibleTiles x: 1, y: 1
      items = _.filter(tiles, (tile) -> tile.type == 'treasure' )
      expect(items).toEqual [@treasure_x0y1.anonPayload()]

    it "returns all players visible", ->
      @player = new Player(1, {x: 1, y: 1})
      @player2 = new Player(2, {x: 1, y: 2})
      @game.players = [@player, @player2]
      tiles = @game.visibleTiles x: 1, y: 1
      players = _.filter(tiles, (tile) -> tile.type == 'player' )
      expect(players).toEqual [@player.anonPayload(), @player2.anonPayload()]

    it "returns all stashes visible", ->
      # TODO refactor stash to object with anonPAyload method, then implement this spec

  describe "processAttacks", ->
    beforeEach ->
      @game.map = [
        ["f", "W", "f"],
        ["f", "f", "f"],
        ["f", "f", "W"]
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

  describe "processPickups", ->
    beforeEach ->
      @game.map = [
        ["f", "W", "f"],
        ["f", "f", "f"],
        ["f", "f", "W"]
      ]

      @player = new Player(1, x: 1, y: 1)
      @game.players.push @player
      treasure_pos = {x: 1, y: 1}
      @item = new Treasure(treasure_pos)
      @game.items.push @item
      @order = new Order(1, "pick up")
      @order.player = @player

    it "rejects the order if there is nothing to pick up at player location", ->
      @game.items = []
      @game.processPickups([@order])
      expect(@game.playerMessages[1]).toEqual [{error: "Nothing to pick up here"}]

    it "calls player#pickup() with the item at the player's location", ->
      spy = spyOn(@player, 'pickup')
      @game.processPickups([@order])
      expect(spy).toHaveBeenCalledWith(@item)

    it "sends a message to the player", ->
      @game.processPickups([@order])
      expect(@game.playerMessages[1]).toEqual [{notice: "You picked up #{@item.name}"}]

    it "removes the item from game.items", ->
      expect(@game.items).toEqual [@item]
      @game.processPickups([@order])
      expect(@game.items).toEqual []

  describe "processDrops", ->
    beforeEach ->
      @player = new Player(1, x: 1, y: 1)
      @stash_pos = @player.stash.position()

      treasure_pos = {x: 1, y: 1}
      @treasure = new Treasure(treasure_pos)

      @game.players.push @player
      @game.items.push @treasure


    describe 'when holding an item', ->
      beforeEach ->
        @player.item_in_hand = @treasure
      describe 'when a player is not on his stash', ->
        beforeEach ->
          @player.x = @stash_pos.x + 10
        beforeEach ->
          @order = new Order(@player.clientId, "drop")
          @order.player = @player
          @game.processDrops([@order])
          
        it 'puts the item back in play', ->
          expect(@game.items).toContain @treasure
        it 'tells the player they dropped the item', ->
          notice = "You dropped #{@treasure.name} onto the map"
          expect(@game.playerMessages[@player.clientId]).toContain {notice}

      describe 'when a player is on his stash', ->
        beforeEach ->
          @player.x = @player.stash.x
          @player.y = @player.stash.y
        describe 'when item is treasure', ->
          beforeEach ->
            @treasure.is_treasure = true
          beforeEach ->
            @deposit_spy = spyOn(@player, 'depositTreasure').andCallThrough()
          beforeEach ->
            @order = new Order(@player.clientId, "drop")
            @order.player = @player
            @game.processDrops([@order])

          it 'calls player#depositTreasure', ->
            expect(@deposit_spy).toHaveBeenCalled()

          it 'removes the treasure from play', ->
            expect(@game.items).not.toContain(@treasure)

          it 'tells the player they deposited treasure', ->
            notice = "You deposited #{@treasure.name} into your stash"
            expect(@game.playerMessages[@player.clientId]).toContain {notice}

    describe 'when not holding an item', ->
      describe 'when a player is on his stash', ->
        it 'does not call depositTreasure (this is us covering our ass)', ->
          @player.item_in_hand = null
          @order = new Order(@player.clientId, "drop")
          @order.player = @player
          depositTreasure_spy = spyOn(@player, 'depositTreasure')
          @game.processDrops([@order])
          expect(depositTreasure_spy).not.toHaveBeenCalled()

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

  describe "#tickPayloadFor", ->
    beforeEach ->
      @game.map = [
        ["f", "W", "f"],
        ["f", "f", "f"],
        ["f", "f", "W"]
      ]
      @player = new Player(1, x: 1, y: 1)
      @game.players.push @player
      @payload = @game.tickPayloadFor(1)

    it "has messages[]", ->
      expect(@payload.messages).toEqual []

    it "has info about the player", ->
      player_info = @payload.you
      expected_keys = "name,health,score,carrying_treasure,item_in_hand,stash,position"
      for key in expected_keys.split(',')
        expect(player_info[key]).toBeDefined()

    it "has tiles", ->
      expect(@payload.tiles).toBeDefined()

  describe "#visualizerTickPayload", ->
    beforeEach ->
      @game.map = [
        ["f", "W", "f"],
        ["f", "f", "f"],
        ["f", "f", "W"]
      ]
      @player = new Player(1, x: 1, y: 1)
      @game.players.push @player
      @game.tick()
      @payload = @game.visualizerTickPayload()

    it "has players", ->
      expect(@payload.players.length).toBeDefined()

    it "has items", ->
      expect(@payload.items.length).toBeDefined()
      # some treasure
      treasures = _.filter @payload.items, (item) -> item.is_treasure == true
      expect(treasures.length).toBeGreaterThan(0)


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
      @far = new Player(1, x: @game.options.player_vision_distance + 5, y: 0)
      @game.players = [@player, @nearby, @far]

    it "should return players within player_vision_distance", ->
      expect(@game.findNearbyPlayers(@player)).toEqual [@nearby]

    it "should not return players farther than vision_distance", ->
      @nearby.y = 50
      @nearby.x = 30
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

  describe "findNearbyItems", ->
    beforeEach ->
      @player = new Player(1, x: 1, y: 1)
      @nearby = new Treasure(@player.position())
      @far = new Treasure(@player.position())
      @far.x = @player.position.x + 1000
      @game.players = [@player]
      @game.items = [@nearby, @far]
      @nearby_items = @game.findNearbyItems(@player)

    it "should return nearby items", ->
      expect(@nearby_items).toContain(@nearby)
      expect(@nearby_items).not.toContain(@far)

  describe "validAttack", ->
    beforeEach ->
      @game.map = [
        ["f", "W", "f"]
        ["f", "f", "f"]
        ["f", "f", "W"]
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

  describe "playerCanPickupItem(player, item)", ->
    it "returns true/false about if player can pick up the item", ->
      treasure_pos = {x: 3, y: 10}
      player = new Player 1, treasure_pos
      treasure = new Treasure(treasure_pos)
      expect(@game.playerCanPickupItem(player, treasure)).toEqual true
      #move player away from treasure
      player.x = 100
      expect(@game.playerCanPickupItem(player, treasure)).toEqual false

  describe "repopTreasure", ->
    it "creates one new treasure per player, in a random position", ->
      #no players, no treasure
      @game.players = []
      expect(@game.treasures().length).toEqual 0

      #2 players, 2 treasures
      p1 = new Player(1, {x: 3, y: 4})
      p2 = new Player(2, {x: 1, y: 1})
      @game.players = [p1, p2]
      @game.repopTreasure()
      expect(@game.treasures().length).toEqual 2
      t1 = @game.treasures()[0]
      t2 = @game.treasures()[1]
      expect(t1.is_treasure).toBeTrue
      expect(t2.is_treasure).toBeTrue
      #in random locations
      expect(t1.position()).toNotEqual t2.position()

  describe "reapOldPlayers", ->
    it "disconnects players that have not moved in the last ten seconds", ->
      p1 = new Player(1, {x: 3, y: 4})
      p2 = new Player(2, {x: 1, y: 1})
      @game.players = [p1, p2]

      p1.last_update = +new Date
      p2.last_update = (+new Date) - 20000

      @game.reapOldPlayers()

      expect(@game.players).not.toContain(p2)
      expect(@game.players).toContain(p1)

  describe "tick", ->
    it "calls reapOldPlayers", ->
      spy = spyOn(@game, 'reapOldPlayers')
      @game.tick()

      expect(spy).toHaveBeenCalled()