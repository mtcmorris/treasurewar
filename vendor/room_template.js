var _ = require("underscore");

RoomTemplate = function RoomTemplate(text) {
  this.coded_coords = [];
  this.height = null;
  this.width = null;

  rows = text.split('\n');

  me = this;
  _.each(rows, function(row, r_index) {
    me.coded_coords[r_index] = row;
  });

  long_x = _.map(me.coded_coords, function(r) { return r.length; } ).max();

  _.each(me.coded_coords, function(y_row, y) {
    while(me.coded_coords[y].length < long_x) {
      me.coded_coords[y] += ' ';
    }
  });


  this.height = this.coded_coords.length;
  this.width = this.coded_coords[0].length;

}

RoomTemplate.prototype = {
  exits: function() {
    var tiles = []
    _.each(this.coded_coords, function(y_row, y) {
      _.each(y_row, function(val, x) {
        if(val==='+') tiles.push([x,y]);
      });
    });
    return tiles;
  }
}

RoomTemplate.rooms = function() {
  return ["W+WWWWWW\n\
Wffffff+\n\
WffffffW\n\
WWWWfffW\n\
   WfffW\n\
   +fffW\n\
   WW+WW\n"
,
"WWW+WWW\n\
Wfffff+\n\
WfffffW\n\
+fffffW\n\
WWW+WWW"
,
"WWW+W\n\
WfffW\n\
WfffW\n\
+fffW\n\
WfffWWWWW\n\
Wfffffff+\n\
WfffffffW\n\
W+WWWWWWW"
,
"WWW+WWWWWWW\n\
WfffffffffW\n\
Wfffffffff+\n\
WfffffffffW\n\
WfffffffffW\n\
+fffffffffW\n\
WfffffffffW\n\
WWWWW+WWWWW"
,
"W+WW       WW+W\n\
WffWW     WWffW\n\
+fffWWW WWWfff+\n\
WfffffWWWfffffW\n\
WWWffffWffffWWW\n\
  WWfffffffWW\n\
WWWffffWffffWWW\n\
WfffffWWWfffffW\n\
+fffWWW WWWfff+\n\
WffWW     WWffW\n\
W+WW       WW+W"
,
"WWW+WWW\n\
WfffffW\n\
WfffffW\n\
+fffffW\n\
WfffffW\n\
WfffffW\n\
WfffffW\n\
Wfffff+\n\
WfffffW\n\
WfffffW\n\
WW+WWWW"
,
"WWW+WWWWWWWW\n\
WffffffffffW\n\
Wffffffffff+\n\
WffffffWWWWW\n\
WffffffW\n\
WffffffW\n\
WfffWWWW\n\
+fffW\n\
WfffW\n\
WW+WW"];
}