require("../lib/models/treasure")

describe "Treasure", ->
  beforeEach ->
    @treasure = new Treasure({x: 1, y: 1})

  it 'is treasure', ->
    expect(@treasure.is_treasure).toEqual true

  it 'is an item', ->
    expect(@treasure.is_item).toEqual true

  it 'has a position', ->
    expect(@treasure.position()).toEqual({x: 1, y: 1})

