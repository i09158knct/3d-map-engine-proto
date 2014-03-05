$(function() {
  var ControllerViewModel, animate, camera, controls, render, renderer, updateCamera;
  window.scene = new THREE.Scene();
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.getElementById('container').appendChild(renderer.domElement);
  window.directionalLight = new THREE.DirectionalLight(0xffffffff, 1);
  directionalLight.position.set(1000, -10000, 750);
  scene.add(directionalLight);
  window.directionalLight2 = new THREE.DirectionalLight(0xffffffff, 0.3);
  directionalLight2.position.set(-1000, -1000, -750);
  scene.add(directionalLight2);
  window.directionalLight3 = new THREE.DirectionalLight(0xffffffff, 1);
  directionalLight3.position.set(1000, 1000, 750);
  scene.add(directionalLight3);
  window.cube = new THREE.Mesh(new THREE.CubeGeometry(10, 10, 10), new THREE.MeshBasicMaterial({
    color: 0x00ff00
  }));
  cube.position.set(0, 0, 0);
  scene.add(cube);
  camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 30 * 1000);
  scene.add(camera);
  controls = new THREE.TrackballControls(camera, renderer.domElement);
  camera.position.set(1000, 1000, 1000);
  camera.position.add(cube.position);
  controls.target = cube.position;
  window.moveStates = {
    left: false,
    right: false,
    up: false,
    down: false
  };
  updateCamera = function() {
    if (moveStates.left) {
      camera.position.x -= 20;
      controls.target.x -= 20;
    }
    if (moveStates.right) {
      camera.position.x += 20;
      controls.target.x += 20;
    }
    if (moveStates.up) {
      camera.position.z -= 20;
      controls.target.z -= 20;
    }
    if (moveStates.down) {
      camera.position.z += 20;
      return controls.target.z += 20;
    }
  };
  render = function() {
    controls.update();
    updateCamera();
    return renderer.render(scene, camera);
  };
  requestAnimationFrame(animate = function() {
    requestAnimationFrame(animate);
    if (!window.isStoping) {
      return render();
    }
  });
  ControllerViewModel = (function() {
    function ControllerViewModel(_arg) {
      var boundary, center, getTile, getTileCentroid, scene, target, _centerLat, _centerLon, _ref, _ref1;
      scene = _arg.scene, target = _arg.target;
      boundary = tileToBoundary(target.x, target.y, target.z);
      center = centroid(boundary);
      this.mainlayer = new OverpassLayer({
        scene: scene,
        center: center
      });
      this.tileLocation = {
        lon: ko.observable(center[0]),
        lat: ko.observable(center[1])
      };
      getTile = (function(_this) {
        return function() {
          var lat, lon, x, y, z, _ref, _ref1, _ref2;
          lon = +_this.tileLocation.lon();
          lat = +_this.tileLocation.lat();
          z = +((_ref = (_ref1 = _this.tile) != null ? typeof _ref1.z === "function" ? _ref1.z() : void 0 : void 0) != null ? _ref : target.z);
          _ref2 = lonlatToTile(lon, lat, z), x = _ref2[0], y = _ref2[1];
          return {
            x: x,
            y: y,
            z: z
          };
        };
      })(this);
      getTileCentroid = function(x, y, z) {
        var lat, lon, _ref;
        boundary = tileToBoundary(+x, +y, +z);
        return _ref = centroid(boundary), lon = _ref[0], lat = _ref[1], _ref;
      };
      this.tile = {
        x: ko.computed({
          read: (function(_this) {
            return function() {
              return getTile().x;
            };
          })(this),
          write: (function(_this) {
            return function(x) {
              var lat, lon, y, z, _ref, _ref1, _x;
              x = +x;
              _ref = getTile(), _x = _ref._x, y = _ref.y, z = _ref.z;
              _ref1 = getTileCentroid(x, y, z), lon = _ref1[0], lat = _ref1[1];
              return _this.tileLocation.lon(lon);
            };
          })(this)
        }),
        y: ko.computed({
          read: (function(_this) {
            return function() {
              return getTile().y;
            };
          })(this),
          write: (function(_this) {
            return function(y) {
              var lat, lon, x, z, _ref, _ref1, _y;
              y = +y;
              _ref = getTile(), x = _ref.x, _y = _ref._y, z = _ref.z;
              _ref1 = getTileCentroid(x, y, z), lon = _ref1[0], lat = _ref1[1];
              return _this.tileLocation.lat(lat);
            };
          })(this)
        }),
        z: ko.observable(target.z)
      };
      this.boundary = {
        s: ko.observable(),
        w: ko.observable(),
        n: ko.observable(),
        e: ko.observable()
      };
      _centerLon = ko.observable((_ref = center.lon) != null ? _ref : center[0]);
      _centerLat = ko.observable((_ref1 = center.lat) != null ? _ref1 : center[1]);
      this.center = {
        lon: ko.computed({
          read: function() {
            return _centerLon();
          },
          write: (function(_this) {
            return function(lon) {
              _centerLon(+lon);
              return _this.updateCenter();
            };
          })(this)
        }),
        lat: ko.computed({
          read: function() {
            return _centerLat();
          },
          write: (function(_this) {
            return function(lat) {
              _centerLat(+lat);
              return _this.updateCenter();
            };
          })(this)
        })
      };
      this.isStoping = ko.observable();
    }

    ControllerViewModel.prototype.stop = function() {
      window.isStoping = true;
      return this.isStoping(true);
    };

    ControllerViewModel.prototype.start = function() {
      window.isStoping = false;
      return this.isStoping(false);
    };

    ControllerViewModel.prototype.updateCenter = function() {
      var lat, lon;
      lon = +this.center.lon();
      lat = +this.center.lat();
      this.mainlayer.project = this.mainlayer.project.center([lon, lat]);
      return this.mainlayer.renderer.project = this.mainlayer.renderer.project.center([lon, lat]);
    };

    ControllerViewModel.prototype.loadTile = function() {
      var tile;
      tile = {
        x: +this.tile.x(),
        y: +this.tile.y(),
        z: +this.tile.z()
      };
      return this.load(tile);
    };

    ControllerViewModel.prototype.loadBoundary = function() {
      var boundary, tile;
      boundary = ko.toJS(this.boundary);
      tile = boundaryToTile(boundary);
      return this.load(tile);
    };

    ControllerViewModel.prototype.load = function(tile) {
      console.log('loading', tile);
      return this.mainlayer.createPanel(tile).then(function() {
        return console.log('rendered', tile);
      }).fail(function(err) {
        window.err = err;
        return console.error(err.stack);
      });
    };

    ControllerViewModel.prototype.removeAll = function() {
      return this.mainlayer.clear();
    };

    return ControllerViewModel;

  })();
  window.tp = {
    x: 14271,
    y: 6531,
    z: 14
  };
  window.tp2 = {
    x: 14501,
    y: 6414,
    z: 14
  };
  window.target = tp2;
  window.vm = new ControllerViewModel({
    scene: scene,
    target: target
  });
  ko.applyBindings(vm);
  return vm.load(target);
});
