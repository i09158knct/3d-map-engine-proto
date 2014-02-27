var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function() {
  var OverpassLayer, OverpassObjectManager, OverpassRenderer, getMembers, getNodes, isArea, parseData, toAssoc;
  toAssoc = function(elems) {
    var acc;
    acc = {
      node: {},
      way: {},
      relation: {}
    };
    elems.forEach(function(elem) {
      return acc[elem.type][elem.id] = elem;
    });
    return acc;
  };
  parseData = function(overpassData) {
    return toAssoc(overpassData.elements);
  };
  getNodes = function(assoc, way) {
    return way.nodes.map(function(id) {
      return assoc.node[id];
    });
  };
  getMembers = function(assoc, rel) {
    return rel.members.map(function(member) {
      var id, type;
      type = member.type;
      id = member.ref;
      return assoc[type][id];
    });
  };
  isArea = function(way) {
    var first, last;
    first = _.first(way.nodes);
    last = _.last(way.nodes);
    return first === last;
  };
  window.midpoint = function(_arg, _arg1) {
    var x, x1, x2, y, y1, y2;
    x1 = _arg[0], y1 = _arg[1];
    x2 = _arg1[0], y2 = _arg1[1];
    x = x1 - (x1 - x2) / 2;
    y = y1 - (y1 - y2) / 2;
    return [x, y];
  };
  window.centroid = function(boundary) {
    var p1, p2;
    p1 = [boundary.w, boundary.n];
    p2 = [boundary.e, boundary.s];
    return midpoint(p1, p2);
  };
  window.lonlatToTile = function(lon, lat, zoom, isFloat) {
    var lonDegreesPerTile, numOfTiles, sinLat, tx, ty;
    if (isFloat == null) {
      isFloat = false;
    }
    numOfTiles = Math.pow(2, zoom);
    lonDegreesPerTile = 360 / numOfTiles;
    sinLat = Math.sin(lat * Math.PI / 180);
    tx = (lon + 180) / lonDegreesPerTile;
    ty = (0.5 + -0.5 * Math.log((1 + sinLat) / (1 - sinLat)) / (2 * Math.PI)) * numOfTiles;
    if (isFloat) {
      return [tx, ty];
    } else {
      return [Math.floor(tx), Math.floor(ty)];
    }
  };
  window.tileTolonlat = function(tx, ty, zoom) {
    var lat, latRadians, lon, numOfTiles, x, y;
    numOfTiles = Math.pow(2, zoom);
    tx %= numOfTiles;
    ty %= numOfTiles;
    x = tx / numOfTiles;
    y = ty / numOfTiles;
    lon = (x - (1 / 2)) / (1 / 360);
    latRadians = (y - (1 / 2)) / -(1 / (2 * Math.PI));
    lat = (2 * Math.atan(Math.exp(latRadians)) - Math.PI / 2) / Math.PI * 180;
    return [lon, lat];
  };
  window.tileToBoundary = function(x, y, zoom) {
    var p1, p2;
    p1 = tileTolonlat(x, y, zoom);
    p2 = tileTolonlat(x + 1, y + 1, zoom);
    return {
      n: p1[1],
      w: p1[0],
      s: p2[1],
      e: p2[0]
    };
  };
  OverpassObjectManager = (function() {
    function OverpassObjectManager() {}

    return OverpassObjectManager;

  })();
  OverpassRenderer = (function() {
    var lonlatAsArray, xyAsVec3;

    lonlatAsArray = function(_arg) {
      var lat, lon;
      lon = _arg.lon, lat = _arg.lat;
      return [lon, lat];
    };

    xyAsVec3 = function(_arg) {
      var x, y;
      x = _arg[0], y = _arg[1];
      return new THREE.Vector3(x, y, 0);
    };

    OverpassRenderer.prototype.materialOptions = {
      highway: {
        primary: {
          color: 0xff0000,
          linewidth: 1000
        },
        residential: {
          color: 0xffffff,
          linewidth: 2
        },
        "default": {
          color: 0xff0000,
          linewidth: 1
        }
      },
      waterway: {
        "default": {
          color: 0x0000ff,
          linewidth: 10
        }
      },
      amenity: {
        school: {
          color: 0x00aa00,
          amount: 1
        },
        "default": {
          color: 0x00ff00,
          amount: 100
        }
      },
      building: {
        yes: {
          color: 0x888888,
          amount: 50
        },
        "default": {
          color: 0xffffff,
          amount: 1
        }
      }
    };

    function OverpassRenderer(project, materialOptions) {
      this.project = project;
      if (materialOptions == null) {
        materialOptions = {};
      }
      this.createShape = __bind(this.createShape, this);
      _.extend(this.materialOptions, materialOptions);
      this.root = new THREE.Object3D();
      this.root.rotation.x = 90 * Math.PI / 180;
      this.root.scale.z = -1;
    }

    OverpassRenderer.prototype.nodeToXy = function(node) {
      return this.project(lonlatAsArray(node));
    };

    OverpassRenderer.prototype.nodeToVec3 = function(node) {
      return xyAsVec3(this.nodeToXy(node));
    };

    OverpassRenderer.prototype.createFloor = function(boundary) {
      var floor, geometry, nodes, shape;
      nodes = [
        {
          lon: boundary.w,
          lat: boundary.n
        }, {
          lon: boundary.w,
          lat: boundary.s
        }, {
          lon: boundary.e,
          lat: boundary.s
        }, {
          lon: boundary.e,
          lat: boundary.n
        }
      ];
      shape = this.createShape(nodes);
      geometry = shape.extrude({
        amount: 1,
        bevelEnabled: false
      });
      floor = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({
        color: 0x333333
      }));
      floor.position.z = -120;
      this.root.add(floor);
      return floor;
    };

    OverpassRenderer.prototype.findMaterialOptions = function(tags) {
      var category, key, mkeys, tkeys, tvalue, _ref;
      if (tags == null) {
        tags = {};
      }
      mkeys = _.keys(this.materialOptions);
      tkeys = _.keys(tags);
      key = _.first(_.intersection(mkeys, tkeys));
      if (key != null) {
        category = this.materialOptions[key];
        tvalue = tags[key];
        return (_ref = category[tvalue]) != null ? _ref : category["default"];
      } else {
        return null;
      }
    };

    OverpassRenderer.prototype.process = function(data) {
      var lines, points, polygons;
      this.assoc = parseData(data);
      points = [];
      lines = this.processLines();
      return polygons = this.processPolygons();
    };

    OverpassRenderer.prototype.processPoints = function() {
      return _.each(this.assoc.node, (function(_this) {
        return function(node) {
          return _this.root.add(_this.createPoint(node, 0xffff00));
        };
      })(this));
    };

    OverpassRenderer.prototype.processLines = function() {
      var ways;
      ways = _.filter(this.assoc.way, function(way) {
        return !isArea(way);
      });
      return _.each(ways, (function(_this) {
        return function(way) {
          var opts;
          opts = _this.findMaterialOptions(way.tags);
          return _this.root.add(_this.createLine(way, opts));
        };
      })(this));
    };

    OverpassRenderer.prototype.processPolygons = function() {
      var areas;
      areas = _.filter(this.assoc.way, isArea);
      return _.each(areas, (function(_this) {
        return function(area) {
          var opts;
          opts = _this.findMaterialOptions(area.tags);
          return _this.root.add(_this.createPolygon(area, opts));
        };
      })(this));
    };

    OverpassRenderer.prototype.createPoint = function(node, color) {
      var point;
      if (color == null) {
        color = 0xff0000;
      }
      point = new THREE.Mesh(new THREE.SphereGeometry(5), new THREE.MeshBasicMaterial({
        color: color
      }));
      point.position = this.nodeToVec3(node);
      return point;
    };

    OverpassRenderer.prototype.createShape = function(nodes) {
      var shape;
      shape = new THREE.Shape();
      shape.moveTo.apply(shape, this.nodeToXy(nodes[0]));
      nodes.slice(1).forEach((function(_this) {
        return function(node) {
          return shape.lineTo.apply(shape, _this.nodeToXy(node));
        };
      })(this));
      return shape;
    };

    OverpassRenderer.prototype.createLine = function(way, opts) {
      var createWay, line;
      createWay = (function(_this) {
        return function(way) {
          var geometry, nodes;
          nodes = getNodes(_this.assoc, way);
          geometry = new THREE.Geometry();
          geometry.vertices = nodes.map(function(node) {
            return _this.nodeToVec3(node);
          });
          return geometry;
        };
      })(this);
      return line = new THREE.Line(createWay(way), new THREE.LineBasicMaterial(opts));
    };

    OverpassRenderer.prototype.createPolygon = function(area, opts) {
      var createBuilding, poly;
      if (opts == null) {
        opts = {
          color: 0xffffff,
          opacity: 0.8,
          transparent: true
        };
      }
      createBuilding = (function(_this) {
        return function(area, opts) {
          var geometry, nodes, shape;
          nodes = getNodes(_this.assoc, area);
          shape = _this.createShape(nodes);
          return geometry = shape.extrude(_.defaults(opts, {
            amount: 5,
            bevelEnabled: false
          }));
        };
      })(this);
      return poly = new THREE.Mesh(createBuilding(area, opts), new THREE.MeshBasicMaterial(opts));
    };

    OverpassRenderer.prototype.createTihyo = function(boundary, dem, mapimage) {
      var geometry, latDegreesPerSegment, lonDegreesPerSegment, tihyo, xlength, ylength;
      xlength = dem[0].length;
      ylength = dem.length;
      lonDegreesPerSegment = (boundary.e - boundary.w) / xlength;
      latDegreesPerSegment = (boundary.n - boundary.s) / ylength;
      geometry = new THREE.PlaneGeometry(0, 0, xlength - 1, ylength - 1);
      dem.forEach((function(_this) {
        return function(row, yindex) {
          return row.forEach(function(height, xindex) {
            var lat, lon, vertex, x, y, _ref;
            lon = boundary.w + lonDegreesPerSegment * xindex;
            lat = boundary.n - latDegreesPerSegment * yindex;
            _ref = _this.project([lon, lat]), x = _ref[0], y = _ref[1];
            vertex = geometry.vertices[xindex + (yindex * xlength)];
            vertex.x = x;
            vertex.y = y;
            return vertex.z = dem[yindex][xindex] / 5;
          });
        };
      })(this));
      geometry.computeFaceNormals();
      geometry.computeVertexNormals();
      tihyo = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({
        map: mapimage
      }));
      tihyo.position.z = -100;
      this.root.add(tihyo);
      return tihyo;
    };

    return OverpassRenderer;

  })();
  return window.OverpassLayer = OverpassLayer = (function(_super) {
    __extends(OverpassLayer, _super);

    OverpassLayer.prototype.resouces = [Geo.Resouce.overpass, Geo.Resouce.dem, Geo.Resouce.relief];

    OverpassLayer.prototype.overpassData = {};

    OverpassLayer.prototype.panels = [];

    OverpassLayer.prototype.elements = {
      node: {},
      way: {},
      relation: {}
    };

    function OverpassLayer(_arg) {
      var center;
      this.scene = _arg.scene, center = _arg.center;
      this.project = d3.geo.mercator().scale(10 * 100000).center(center).translate([0, 0]);
      this.renderer = new OverpassRenderer(this.project);
    }

    OverpassLayer.prototype.clear = function() {
      var objs;
      objs = _.rest(this.renderer.root.children, 1);
      return _.each(objs, (function(_this) {
        return function(obj) {
          return _this.renderer.root.remove(obj);
        };
      })(this));
    };

    OverpassLayer.prototype.createPanel = function(tile) {
      window.boundary = tileToBoundary(tile.x, tile.y, tile.z);
      this.scene.add(this.renderer.root);
      this.renderer.createFloor(boundary);
      return this.loadResouces(boundary, tile, tile).spread((function(_this) {
        return function(data, dem, mapimage) {
          _this.renderer.createTihyo(boundary, dem, mapimage);
          return _this.renderer.process(data);
        };
      })(this));
    };

    return OverpassLayer;

  })(Geo.Layer);
})();
