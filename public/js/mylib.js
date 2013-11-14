function loadText(url) {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', url, false);
  xhr.send();
  return xhr.responseText;
}


// https://developers.google.com/maps/documentation/javascript/examples/map-coordinates
function latLngToTile(lat, lng, zoom) {
  var NUM_OF_TILES = Math.pow(2, zoom);
  var LNG_DEGREES_PER_TILE = 360 / NUM_OF_TILES;

  var sinLat = Math.sin(lat * Math.PI / 180);

  return {
    x: (lng + 180) / LNG_DEGREES_PER_TILE,
    y: (0.5 + -0.5 * Math.log((1 + sinLat) / (1 - sinLat)) / (2 * Math.PI)) * NUM_OF_TILES
  };
}

function tileTolatLng(x, y, zoom) {
  zoom = zoom || 14;

  x /= Math.pow(2, zoom);
  y /= Math.pow(2, zoom);

  var lng = (x - (1 / 2)) / (1 / 360);
  var latRadians = (y - (1 / 2)) / -(1 / (2 * Math.PI));
  var lat = (2 * Math.atan(Math.exp(latRadians)) - Math.PI / 2) / Math.PI * 180;

  return {latitude: lat, longitude: lng};
}

function latLngToWorld(lat, lng) {
  var METERS_PER_DEGREE = 40000 * 1000 / 360;

  return {
    // x: (lng + 180) * METERS_PER_DEGREE, // 酷いブレ
    x: (lng) * METERS_PER_DEGREE,
    y: (90 - lat) * METERS_PER_DEGREE
  };
}

function getTileCord(opts) {
  var zoom = 14;
  var tile = ('x' in opts && 'y' in opts) ?
    opts :
    latLngToTile(opts.latitude, opts.longitude, zoom);

  return {x: ~~ tile.x, y: ~~ tile.y};
}

function buildGroundMesh(opts) {
  var zoom = 14;
  var roughness = opts.roughness;
  var tileCord = getTileCord(opts);

  var factor = Math.pow(2, roughness || 0);
  var xlength = 256 / factor;
  var ylength = 256 / factor;

  // 日本程度の緯度の場合、ズームレベル14のタイル1枚の縦横の長さは
  // だいたい1700mぐらいになる
  var geometry = new THREE.PlaneGeometry(
    1.7 * 1000,
    1.7 * 1000,
    xlength - 1,
    ylength - 1
    );

  var dem = loadText([
      'data', 'dem', zoom, tileCord.x, tileCord.y + '.txt'
    ].join('/')).split('\n').map(function(row) {
    return row.split(',').map(function(height) {
      return parseFloat(height) || -1;
    });
  });

  for (var y = 0; y < xlength; y++) {
    for (var x = 0; x < ylength; x++) {
      var vertex = geometry.vertices[x + (y * xlength)];
      vertex.z = dem[y * factor][x * factor];
    }
  }
  geometry.computeFaceNormals();
  geometry.computeVertexNormals();


  return new THREE.Mesh(
    geometry,
    new THREE.MeshBasicMaterial({
      map: THREE.ImageUtils.loadTexture([
        'data', 'relief', zoom, tileCord.x, tileCord.y + '.png'
      ].join('/'))
    })
  );
}


function GroundMeshLoader() {
  this.grounds = {};
}

GroundMeshLoader.prototype = {
  // TODO: ロードと配置の処理は分けるべき。Google Maps の MapTypes みたいに
  load: function(opts) {
    var tileCord = getTileCord(opts);
    var tileLatLng = tileTolatLng(tileCord.x, tileCord.y);
    var worldCord = latLngToWorld(tileLatLng.latitude, tileLatLng.longitude);

    var ground = buildGroundMesh(opts);
    ground.rotation.x = Math.PI / -2;

    ground.position.x = worldCord.x;
    ground.position.z = worldCord.y;

    this.setGround(tileCord.x, tileCord.y, ground);
    return ground;
  },

  setGround: function(x, y, ground) {
    this.grounds[x + ',' + y] = ground;
  },

  getGround: function(x, y) {
    return this.grounds[x + ',' + y];
  }
};