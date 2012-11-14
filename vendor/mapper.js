var sys = require("sys");
var _ = require("underscore");
require("./array.js");


Mapper = function Mapper(xsize, ysize, room_templates) {

  this.coded_coords = null;
  this.room_templates = null;
  this.xsize = null;
  this.ysize = null;

  this.xsize = parseInt(xsize, 10);
  this.ysize = parseInt(ysize, 10);

  this.room_templates = room_templates;
}
Mapper.prototype = {
  generate_coords: function() {
    var tallest_height, widest_width, y, room_exits;

    this.coded_coords = []

    // tallest room's height and widest rooms width?
    tallest_height = _.map(this.room_templates, function(rt) { return rt.height; } ).max();
    widest_width = _.map(this.room_templates, function(rt) { return rt.width; } ).max();

    y = 0;
    room_exits = [];


    // loop until our rows run out
    while( y < this.ysize ) {
      var rooms, room_for_x, a_room, row_tallest_height, gaps, num_unused_spaces, x;

      // pick some rooms
      rooms = [];
      room_for_x = this.xsize;

      while( room_for_x > widest_width ) {
        a_room = this.room_templates[Math.floor(Math.random() * this.room_templates.length)];
        rooms.push(a_room);
        room_for_x -= (a_room.width + 1);
      }

      // tallest height just for this row
      row_tallest_height = _.map(rooms, function(r) { return r.height; } ).max();

      // 0 spaces on each end, at least 3 spaces in between each room
      arr = new Array(rooms.length - 1);
      for(i=0; i< arr.length; i++){
        arr[i] = 3;
      }

      gaps = [0].concat(arr).concat([0]);

      num_unused_spaces = this.xsize - (3 * rooms.length + _.map(rooms, function(r) { return r.width; }).sum());

      // randomly distribute extra spaces into gaps
      for(i=0; i < num_unused_spaces; i++) {
        gaps[Math.floor(Math.random() * gaps.length)] += 1
      }

      // prepopulate this room-row with blanks
      for(n=y; n < (y + tallest_height); n++) {
        arr = new Array(this.xsize);
        for(i=0; i< arr.length; i++){
          arr[i] = ' ';
        }
        this.coded_coords[n] = arr;
      }

      // shift ahead past first gap
      x = gaps[0];
      me = this;
      // cycle through rooms and populate coded_coords
      _.each(rooms, function(room, index) {
        var extra_y_offset = Math.floor(Math.random() * (row_tallest_height - room.height));
        _.each(room.coded_coords, function(room_y_row, y_in_room) {
          _.each(room_y_row, function(room_value, x_in_room) {
            me.coded_coords[y + y_in_room + extra_y_offset][x + x_in_room] = room_value;
          });
        });

        // collect the exit points, offset for x, y
        _.each(room.exits(), function(e, i) {
          //Fuck knows why this is invalid
          var item = [[e[0]+x, e[1]+y+extra_y_offset]]
          room_exits = room_exits.concat(item);
        });

        // shift past this room and then next gap
        x += room.width + gaps[index+1];
      });

      // _.each(this.coded_coords, function(r, i) {
      //   sys.puts("Row: " + r.toString());
      // });

      y += tallest_height;
      if( y < this.ysize ) {
        for(n=y; n <= (y + 3); n++) {
          arr = new Array(this.xsize);
          for(i=0; i< arr.length; i++){
            arr[i] = ' ';
          }
          this.coded_coords[n] = arr;
        }
        y += 3;
      }

      // shift y up to one spot past what we have now, for the while loop
      y = this.coded_coords.length;
    } // end while loop through room rows

    // collect exit pairs - get the actual stub that sticks out from an exit if one exists
    var usable_room_exit_pairs = [];
    var the_mapper = this;

    _.each(room_exits, function(exit, exit_index) {
      var _wef = the_mapper.wheres_empty_from(exit[0],exit[1]);
      if(_wef) usable_room_exit_pairs.push([exit, _wef]);
    });

    // randomly sort the exit pairs
    usable_room_exit_pairs.sort( function() { return 0.5 - Math.random(); } );

    var used_exits = [];

    // now draw corridors by looping through all possible links between exits
    _.each(usable_room_exit_pairs, function(exit_pair, exit_index) {
      var other_exit_pairs = usable_room_exit_pairs.slice();
      other_exit_pairs.splice(exit_index, 1);
      _.each(other_exit_pairs, function(other_pair, other_exit_index) {
        var other_orig = other_pair[0];
        var other_outer_exit = other_pair[1];
        var this_orig = exit_pair[0];
        var outer_exit = exit_pair[1];
        if( the_mapper.is_clear_from_to(outer_exit[0], outer_exit[1], other_outer_exit[0], other_outer_exit[1]) ) {
          the_mapper.draw_corridor_from_to(outer_exit[0], outer_exit[1], other_outer_exit[0], other_outer_exit[1])
          the_mapper.coded_coords[this_orig[1]][this_orig[0]] = 'f';
          the_mapper.coded_coords[other_orig[1]][other_orig[0]] = 'f';
          used_exits.push(this_orig);
          used_exits.push(other_orig);
        }
      });
    });

    this.surround_every_floor_with_wall();
  },

  toText: function() {
    return _.map(this.coded_coords, function(cc) { return cc.join(''); }).join('\n');
  },

  toHTML: function() {
    return _.map(this.coded_coords,
      function(cc) { return _.map(cc, function(c) {
        return '<div class="t ' + (c === 'W' || c === 'f' ? c : '') + '">' +
          (c === ' ' ? '&nbsp;' : c) + '</div>'; }).join('');
      }).join('<br/>');
  },


  // actually picks the random points for the corridor given the start and end and modifies the 2D array
  draw_corridor_from_to: function(x1, y1, x2, y2) {
    var h_mod, v_mod, x, y;
    h_mod = x1 < x2 ? 1 : -1;
    v_mod = y1 < y2 ? 1 : -1;
    x = x1;
    y = y1;

    while( x !== x2 || y !== y2) {
      this.coded_coords[y][x] = 'f'
      if(x != x2 && Math.random() > 0.5) {
        x += h_mod;
      } else if(y != y2) {
        y += v_mod;
      }
    }
    this.coded_coords[y][x] = 'f'
  },

  /* utility functions to assist with mapping */

  wheres_empty_from: function(x,y) {
    if(this.north_from(x,y) === ' ') return [x,   y-1];
    if(this.south_from(x,y) === ' ') return [x,   y+1];
    if(this.west_from(x,y)  === ' ') return [x-1, y  ];
    if(this.east_from(x,y)  === ' ') return [x+1, y  ];
    return false;
  },

  north_from: function(x,y) { return (y > 0 ? this.coded_coords[y-1][x] : null); },

  south_from: function(x,y) { return (y < (this.coded_coords.length-1) ? this.coded_coords[y+1][x] : null); },

  west_from: function(x,y) { return (x > 0 ? this.coded_coords[y][x-1] : null); },

  east_from: function(x,y) { return (x < (this.coded_coords[0].length-1) ? this.coded_coords[y][x+1] : null); },

  northeast_from: function(x,y) { return ((y > 0 && x > 0) ? this.coded_coords[y-1][x+1] : null); },

  southeast_from: function(x,y) { return ((y > 0 && x > 0) ? this.coded_coords[y+1][x+1] : null); },

  northwest_from: function(x,y) { return ((y > 0 && x > 0) ? this.coded_coords[y-1][x-1] : null); },

  southwest_from: function(x,y) { return ((y > 0 && x > 0) ? this.coded_coords[y+1][x-1] : null); },

  // returns true only if you have a rectangle of empty spaces between the two points given
  is_clear_from_to: function(x1, y1, x2, y2) {
    start_x = [x1,x2].min();
    end_x = [x1,x2].max();
    start_y = [y1,y2].min();
    end_y = [y1,y2].max();
    for(y=start_y; y <= end_y; y++) {
      for(x=start_x; x <= end_x; x++) {
        if(this.coded_coords[y][x] !== ' ') return false;
      }
    }
    return true;
  },

  // makes sure there are walls where appropriate - do after drawing corridors
  surround_every_floor_with_wall: function() {
    var the_mapper = this;
    _.each(this.coded_coords, function(y_row, y) {
      _.each(y_row, function(tile, x) {
        if(tile === 'f') {
          if(the_mapper.north_from(x,y)     === ' ') the_mapper.coded_coords[y-1][x  ]   = 'W'
          if(the_mapper.south_from(x,y)     === ' ') the_mapper.coded_coords[y+1][x  ]   = 'W'
          if(the_mapper.west_from(x,y)      === ' ') the_mapper.coded_coords[y  ][x-1]   = 'W'
          if(the_mapper.east_from(x,y)      === ' ') the_mapper.coded_coords[y  ][x+1]   = 'W'
          if(the_mapper.northeast_from(x,y) === ' ') the_mapper.coded_coords[y-1][x+1]   = 'W'
          if(the_mapper.southeast_from(x,y) === ' ') the_mapper.coded_coords[y+1][x+1]   = 'W'
          if(the_mapper.northwest_from(x,y) === ' ') the_mapper.coded_coords[y-1][x-1]   = 'W'
          if(the_mapper.southwest_from(x,y) === ' ') the_mapper.coded_coords[y+1][x-1]   = 'W'
        } else if(tile === '+') {
          the_mapper.coded_coords[y][x] = 'W'
        }
      });
    });
  }
}
