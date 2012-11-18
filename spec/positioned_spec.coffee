_ = require("underscore")
positioned_properties = require("../lib/mixins/positioned").positioned_properties

describe "Positioned mixin", ->
  beforeEach ->
    @positioned = _.extend {}, positioned_properties

  describe '#position', ->
    it 'returns {x, y}', ->
      @positioned.x = 5
      @positioned.y = 6
      expect(@positioned.position()).toEqual({x: 5, y: 6})

  describe '#setPosition', ->
    it "updates the object's x and y", ->
      @positioned.x = 1
      @positioned.y = 2
      @positioned.setPosition(3, 4)
      expect(@positioned.position()).toEqual {x: 3, y: 4}
