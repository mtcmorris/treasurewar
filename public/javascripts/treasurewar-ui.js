(function() {
  var Sprites, TreasureWarUI, animations, char, data, getMap, spriteData, tileTypes,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  tileTypes = {
    'W': {
      name: 'walls',
      frames: [17, 18, 19]
    },
    'f': {
      name: 'floors',
      frames: [23, 24, 25]
    },
    'p': {
      name: 'players',
      frames: [0, 1, 2, 3, 4, 5]
    },
    't': {
      name: 'treasures',
      frames: [12, 13, 14]
    },
    ' ': {
      name: 'other',
      frames: [29, 30, 31]
    }
  };

  animations = {};

  for (char in tileTypes) {
    data = tileTypes[char];
    animations[char] = {
      frames: data.frames
    };
  }

  spriteData = {
    images: ["sprite.png"],
    animations: animations,
    frames: {
      width: 40,
      height: 40
    }
  };

  getMap = function() {
    var done,
      _this = this;
    done = null;
    $.get('http://127.0.0.1:1337').done(function(data) {
      return done = data;
    });
    return JSON.parse(done);
  };

  Sprites = (function() {

    function Sprites() {
      this.spritesheet = new createjs.SpriteSheet(spriteData);
      this.sprite = new createjs.BitmapAnimation(this.spritesheet);
    }

    Sprites.prototype.show = function(index, stage, x, y) {
      stage.addChild(this.sprite);
      this.sprite.gotoAndPlay(index);
      this.sprite.x = x;
      return this.sprite.y = y;
    };

    return Sprites;

  })();

  TreasureWarUI = (function() {

    function TreasureWarUI() {
      this.handleImageLoad = __bind(this.handleImageLoad, this);
      this.loaded = 0;
    }

    TreasureWarUI.prototype.handleImageLoad = function(event) {
      var _this = this;
      this.loaded = this.loaded + 1;
      console.log(this.loaded);
      if (this.loaded === 1) {
        return $.get('http://127.0.0.1:1337').done(function(data) {
          _this.map = JSON.parse(data);
          return _this.renderMap();
        });
      }
    };

    TreasureWarUI.prototype.randomFrame = function(frames) {
      return _.first(_(frames).shuffle());
    };

    TreasureWarUI.prototype.randomSprite = function(char, pos) {
      var index, s;
      s = new Sprites;
      index = this.randomFrame(tileTypes[char].frames);
      return s.show(index, this.stage, pos.x * 40, pos.y * 40);
    };

    TreasureWarUI.prototype.placeFloorTile = function(pos) {
      return this.randomSprite('f', pos);
    };

    TreasureWarUI.prototype.renderMap = function() {
      var cursorX, cursorY, height, pos, tile_name, width, _i, _j;
      width = this.map.x;
      height = this.map.y;
      for (cursorY = _i = 0; 0 <= height ? _i <= height : _i >= height; cursorY = 0 <= height ? ++_i : --_i) {
        for (cursorX = _j = 0; 0 <= width ? _j <= width : _j >= width; cursorX = 0 <= width ? ++_j : --_j) {
          if (this.map.map.length <= cursorY) {
            continue;
          }
          if (this.map.map[cursorY].length <= cursorX) {
            continue;
          }
          char = this.map.map[cursorY][cursorX];
          tile_name = tileTypes[char].name;
          pos = {
            x: cursorX,
            y: cursorY
          };
          if (tile_name === 'players' || tile_name === 'treasures') {
            this.placeFloorTile(pos);
          }
          this.randomSprite(char, pos);
        }
      }
      return this.stage.update();
    };

    TreasureWarUI.prototype.main = function() {
      this.stage = new createjs.Stage("TreasureWar");
      this.sprites = new Image;
      this.sprites.src = "sprite.png";
      return this.sprites.onload = this.handleImageLoad;
    };

    return TreasureWarUI;

  })();

  $(document).ready(function() {
    var ui;
    ui = new TreasureWarUI;
    return ui.main();
  });

}).call(this);
