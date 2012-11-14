require("../../vendor/array.js")
require("../../vendor/mapper.js")
sys     = require('sys')
template = require("../../vendor/room_template.js")

root.Dungeon = class Dungeon
  constructor: (xsize, ysize) ->
    # opts?
    @xsize = xsize
    @ysize = ysize
    @room_templates = for room in RoomTemplate.rooms()
      do (room) ->
        new RoomTemplate(room)

  generate: ->
    map = new Mapper(@xsize, @ysize, @room_templates)
    generated = false
    while(!generated)
      try
        map.generate_coords()
        generated = true
      catch error
        # Yeah ok - it fails some times - clunge it
    map.coded_coords #return as array
    #Return as text: # map.toText()
