require('./dungeon')
_ = require('underscore')
require('./player')
require('./order')
require('./treasure')

root.Game = class Game
  constructor: ->
    @options =
      player_vision_distance: 3

    @mapX = 0
    @mapY = 0
    @map = null
    @players = []
    @orders = {}
    @playerMessages = {}
    @visualizerEvents = []
    @items = []


  spawnDungeon: (x, y) ->
    @mapX = x
    @mapY = y
    dungeon = new Dungeon(@mapX, @mapY)
    @map = dungeon.generate()

  spawnPlayer: (clientId) ->
    player = new Player(clientId, @getRandomFloorLocation())
    player.last_update = +new Date
    @players.push player

  setName: (clientId, name) ->
    @findPlayer(clientId).name = name

  disconnectPlayer: (clientId) ->
    @players = _.reject(@players, (p) -> p.clientId == clientId)

  getRandomFloorLocation: ->
    throw("There is no dungeon") if @map is null
    while(true)
      x = Math.floor(Math.random() * @mapX)
      y = Math.floor(Math.random() * @mapY)
      return {x, y} if @isFloor({x, y})

  isFloor: (position) ->
    @map[position.y][position.x] == 'f'

  registerOrder: (order) ->
    console.log "Order received", order
    @orders[order.clientId] = order

  validMove: (player, direction) ->
    newPos = @translatePosition player.position(), direction
    @isFloor(newPos)

  movePlayer: (player, direction) ->
    newPos = @translatePosition player.position(), direction
    player.x = newPos.x
    player.y = newPos.y

  translatePosition: (position, direction) ->
    pos = _.clone(position)
    if direction.match /n/ then pos.y -= 1
    if direction.match /s/ then pos.y += 1
    if direction.match /e/ then pos.x += 1
    if direction.match /w/ then pos.x -= 1
    pos

  processAttacks: (attack_orders) ->
    for attack in attack_orders
      try
        attacked = @validAttack(attack)
        if attacked
          attacked.health -= 10
          @messageClient(attack.player, notice: "You attacked #{attacked.name}")
          @messageClient(attacked, notice: "You were attacked by #{attack.player.name}")
          if attacked.health <= 0
            attack.player.kills += 1
            @visualizerEvents.push "kill"
          else
            @visualizerEvents.push "attack"
        else
          @messageClient(attack.player, error: "Your attack in dir #{attack.dir} where there was no player")
      catch exception
        console.log "Error processing attack: ", attack

  processPickups: (pickup_orders) ->
    for order in pickup_orders
      try
        player = @findPlayer(order.clientId)
        target_item = @getItemAtPosition(player.position())
        if target_item && @playerCanPickupItem(player, target_item)
          player.pickup(target_item)
          @items = _.filter(@items, (item) -> item.id != target_item.id)
          @messageClient(player, notice: "You picked up #{target_item.name}")
        else
          @messageClient(player, error: "Nothing to pick up here")
      catch exception
        console.log "Error processing pickup: ", pickup

  messageClient: (player, msg) ->
    @playerMessages[player.clientId] ||= []
    @playerMessages[player.clientId].push msg

  validAttack: (attack) ->
    attackedPosition = @translatePosition attack.player.position(), attack.dir
    @findPlayerByPosition attackedPosition

  processDrops: (orders) ->
    for drop_order in orders
      try
        player = @findPlayer(drop_order.clientId)
        drop_result = player.dropHeldItem()
        if dropped_item = drop_result.dropped_item
          if drop_result.did_deposit
            @items = _(@items).without(dropped_item)
            @messageClient(player, notice: "You deposited #{dropped_item.name} into your stash")
          else
            dropped_item.position.x = player.position().x
            dropped_item.position.y = player.position().y
            @items.push dropped_item
            @messageClient(player, notice: "You dropped #{dropped_item.name} onto the map")
      catch exception
        console.log "Error processing drop ", drop_order
        console.log exception
        console.log exception.stack


  tick: ->
    @playerMessages = {}
    @visualizerEvents = []

    # attach player for each order
    orders = _.values(@orders)
    _(orders).map (o) => o.player = @findPlayer(o.clientId)

    @processAttacks _.filter(orders, (order) -> order.command == "attack")
    @processPickups _.filter(orders, (order) -> order.command == "pick up")
    @processDrops _.filter(orders, (order) -> order.command == "drop")
    @processMoves _.filter(orders, (order) -> order.command == "move")
    @respawnDeadPlayers()
    @reapOldPlayers()
    @repopTreasure()
    @updateScores()
    @orders = {}

  reapOldPlayers: ->
    oldPlayers = _(@players).filter( (p) -> p.last_update < (+new Date - 10000) )
    for player in oldPlayers
      console.log "Reaped player #{player.clientId}"
      @disconnectPlayer player.clientId

  respawnDeadPlayers: ->
    deadPlayers = _(@players).filter( (p) -> p.health <= 0)

    for player in deadPlayers
      player.respawn()
      @messageClient(player, notice: "You died :(")

  processMoves: (moveOrders) ->
    for order in moveOrders
      try
        return unless order.player?
        order.player.last_update = +new Date
        if @validMove(order.player, order.dir)
          @movePlayer(order.player, order.dir)
          @messageClient(order.player, notice: "You moved #{order.dir}")
        else
          @messageClient(order.player, error: "Invalid move dir: #{order.dir}")
      catch exception
        console.log "Error processing move ", order


  updateScores: -> player.calcScore() for player in @players

  tickPayloadFor: (clientId) ->
    player = @findPlayer(clientId)

    {
      messages: @playerMessages[clientId] || []
      you: player.tickPayload()
      tiles: @visibleTiles(player.position())
      nearby_players: _.without(@findNearbyPlayers(player)).map((p) -> p.anonPayload())
      nearby_stashes: @findNearbyStashes(player)
      nearby_items: @findNearbyItems(player)
    }

  visualizerTickPayload: ->
    {
      players: @players
      items: @items
      events: @visualizerEvents
    }


  findPlayer: (clientId) ->
    _.find(@players, (p) -> p.clientId == clientId)

  findNear: (options) ->
    dist = @options.player_vision_distance
    pos = options.pos
    switch options.find
      when 'players'
        _.filter(@players, (p) -> Math.abs(p.x - pos.x) <= dist && Math.abs(p.y - pos.y) <= dist)
      when 'stashes'
        _.filter(@players, (p) ->
          Math.abs(p.stash.x - pos.x) <= dist && Math.abs(p.stash.y - pos.y <= dist)
        ).map((p) -> {
          x: p.stash.x,
          y: p.stash.y,
          name: p.name
          treasures: p.stash.treasures
        })
      when 'items'
        _.filter(@items, (i) ->
          Math.abs(i.position().x - pos.x) <= dist && Math.abs(i.position().y - pos.y) <= dist)

  findNearbyPlayers: (player) ->
    _.without(@findNear(find: 'players', pos: player.position()), player)

  findNearbyStashes: (player) ->
    _.without(@findNear(find: 'players', pos: player.position()), player).map((p) -> {
      x: p.stash.x,
      y: p.stash.y,
      name: p.name
      treasure: p.stash.treasure
    })

  findNearbyItems: (player) ->
    @findNear(find: 'items', pos: player.position())

  findPlayerByPosition: (pos) ->
    _.find(@players, (p) -> p.x == pos.x && p.y == pos.y)

  visibleTiles: (pos) ->
    visibles = []

    # get map tiles to show
    dist = @options.player_vision_distance

    for y in [(dist * -1)..dist]
      for x in [(dist * -1)..dist]
        current_x = pos.x + x
        current_y = pos.y + y
        tile = @map[current_y][current_x] if @map[current_y]
        if tile
          tile_type = switch tile
            when "W" then "wall"
            when "f" then "floor"
          visibles.push {x: current_x, y: current_y, type: tile_type}

    # add in players, stashes, items
    items = @findNear(find: 'items', pos: pos)
    item_hashes = _.map(items, (item) -> item.anonPayload())
    visibles = visibles.concat item_hashes

    stashes = @findNear(find: 'stashes', pos: pos)
    stash_hashes = _.map(stashes, (stash) ->
      return _.extend stash, {type: 'stash'}
    )
    visibles = visibles.concat stash_hashes

    players = @findNear(find: 'players', pos: pos)
    player_hashes = _.map(players, (player) -> player.anonPayload())
    visibles = visibles.concat player_hashes

    visibles

  mapToString: ->
    output = "The Map\n"
    _.each @map, (row, y) ->
      output += row + "\n"
    output

  playerCanPickupItem: (player, item) ->
    # Right now, only checks are:
    # - is player at item's position
    # - item has no owner
    same_position = player.position().x == item.position().x && player.position().y == item.position().y
    no_owner = item.owned_by == null
    can_pick_up = same_position && no_owner

  getItemAtPosition: (position) ->
    items = _.filter(@items, (item) -> item.position().x == position.x && item.position().y == position.y)
    item = if items.length > 0 then items[0] else null

  treasures: ->
    _.filter(@items, (item) -> item.is_treasure == true)

  repopTreasure: ->
    # repop one treasure per player somewhere random in the dungeon
    until enough_treasure = @treasures().length >= @players.length
      position = @getRandomFloorLocation()
      treasure_already_at_location = @getItemAtPosition(position)?.is_treasure
      if not treasure_already_at_location
        @items.push new Treasure(position)

