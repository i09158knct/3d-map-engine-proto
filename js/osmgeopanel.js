var __slice = [].slice;

(function(root) {
  var OpenpassLayer, Panel, createBuilding, createFloor, createPoint, createShape, createWay, getMembers, getNodes, isArea, parseData, toAssoc;
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
  root.tPoints = {
    n: 50.74599093970515,
    w: 7.153891324996948,
    s: 50.747956248259705,
    e: 7.156493067741394
  };
  tPoints.p1 = [tPoints.n, tPoints.w];
  tPoints.p2 = [tPoints.s, tPoints.e];
  root.latScale = d3.scale.linear().domain([tPoints.p1[0], tPoints.p2[0]]).range([-500, 500]);
  root.lonScale = d3.scale.linear().domain([tPoints.p1[1], tPoints.p2[1]]).range([-500, 500]);
  root.project = function(node) {
    return [latScale(node.lat), lonScale(node.lon)];
  };
  createPoint = function(node, color) {
    var point;
    if (color == null) {
      color = 0xff0000;
    }
    point = new THREE.Mesh(new THREE.SphereGeometry(5), new THREE.MeshBasicMaterial({
      color: color
    }));
    point.position = new THREE.Vector3(latScale(node.lat), 0, lonScale(node.lon));
    return point;
  };
  createFloor = function() {
    var floor;
    floor = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), new THREE.MeshBasicMaterial({
      color: 0x333333
    }));
    floor.rotation.x = -90 * Math.PI / 180;
    floor.position.y = -0.5;
    return floor;
  };
  createShape = function(way, nodes) {
    var shape;
    shape = new THREE.Shape();
    shape.moveTo.apply(shape, project(nodes[0]));
    nodes.slice(1).forEach(function(node) {
      return shape.lineTo.apply(shape, project(node));
    });
    return shape;
  };
  createBuilding = function(assoc, area) {
    var geometry, nodes, shape;
    nodes = getNodes(assoc, area);
    shape = createShape(area, nodes);
    return geometry = shape.extrude({
      amount: -100,
      bevelEnabled: false,
      material: void 0,
      extrudeMaterial: void 0
    });
  };
  createWay = function(assoc, way) {
    var geometry, nodes;
    nodes = getNodes(assoc, way);
    geometry = new THREE.Geometry();
    geometry.vertices = _.compact(nodes).map(function(node) {
      return new THREE.Vector3(latScale(node.lat), lonScale(node.lon), 0);
    });
    return geometry;
  };
  Panel = (function() {
    Panel.prototype.floor = null;

    Panel.prototype.objects = {
      point: {},
      line: {},
      poly: {}
    };

    Panel.prototype.materialOptions = {
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
        "default": {
          color: 0x00ffff
        }
      },
      building: {
        yes: {
          color: 0xcccccc
        },
        "default": {
          color: 0x00ff00
        }
      }
    };

    function Panel(data) {
      this.assoc = parseData(data);
      this.initFloor();
      this.initPoints();
      this.initOthers();
    }

    Panel.prototype.initFloor = function() {
      return this.floor = this.createFloor(tPoints);
    };

    Panel.prototype.initPoints = function() {
      return _.each(this.assoc.node, (function(_this) {
        return function(node, id) {
          var point;
          point = _this.createPoint(node, 0xffff00);
          return _this.objects.point[id] = point;
        };
      })(this));
    };

    Panel.prototype.initOthers = function() {
      return _.each(this.assoc.way, (function(_this) {
        return function(way, id) {
          var opts;
          opts = _this.findMaterialOptions(way.tags);
          if (isArea(way)) {
            console.log(way.tags);
            return _this.addPolygon(id, way, opts);
          } else if (opts != null) {
            return _this.addLine(id, way, opts);
          }
        };
      })(this));
    };

    Panel.prototype.findMaterialOptions = function(tags) {
      var category, key, mkeys, tkeys, tvalue, _ref;
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

    Panel.prototype.allObjects = function() {
      return __slice.call([this.floor]).concat(__slice.call(_.values(this.objects.point)), __slice.call(_.values(this.objects.line)), __slice.call(_.values(this.objects.poly)));
    };

    Panel.prototype.createPoint = createPoint;

    Panel.prototype.createFloor = createFloor;

    Panel.prototype.createWay = function(way) {
      return createWay(this.assoc, way);
    };

    Panel.prototype.createBuilding = function(area) {
      return createBuilding(this.assoc, area);
    };

    Panel.prototype.addLine = function(id, way, opts) {
      var line;
      line = new THREE.Line(this.createWay(way), new THREE.LineBasicMaterial(opts));
      line.rotation.x = 90 * Math.PI / 180;
      return this.objects.line[id] = line;
    };

    Panel.prototype.addPolygon = function(id, area, opts) {
      var poly;
      poly = new THREE.Mesh(this.createBuilding(area), new THREE.MeshBasicMaterial(opts));
      poly.rotation.x = 90 * Math.PI / 180;
      return this.objects.poly[id] = poly;
    };

    return Panel;

  })();
  root.OpenpassLayer = OpenpassLayer = (function() {
    OpenpassLayer.prototype.resouces = [Geo.Resouce.overpass];

    OpenpassLayer.prototype.panels = [];

    OpenpassLayer.prototype.elements = {
      node: {},
      way: {},
      relation: {}
    };

    function OpenpassLayer() {}

    OpenpassLayer.prototype.loadResouces = function() {
      var params;
      params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return Q.all(this.resouces.map(function(resouce, i) {
        return resouce.load(params[i]);
      }));
    };

    OpenpassLayer.prototype.createPanel = function() {
      var params;
      params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.loadResouces.apply(this, params).then((function(_this) {
        return function(ress) {
          return new Panel(ress[0]);
        };
      })(this)).then((function(_this) {
        return function(panel) {
          return _this.panel = panel;
        };
      })(this)).then(function() {
        return console.log('done');
      }).fail(function() {
        return function(err) {
          return window.err = err;
        };
      });
    };

    OpenpassLayer.utils = {
      toAssoc: toAssoc
    };

    return OpenpassLayer;

  })();
  window.a = new OpenpassLayer();
  return $(function() {
    return a.createPanel(tPoints).then(function() {
      return _.each(a.panel.allObjects(), function(obj) {
        return scene.add(obj);
      });
    });
  });
})(window);
