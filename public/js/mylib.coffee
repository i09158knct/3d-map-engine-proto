loadText = (url) ->
  xhr = new XMLHttpRequest()
  xhr.open 'GET', url, false
  xhr.send()
  xhr.responseText


# https://developers.google.com/maps/documentation/javascript/examples/map-coordinates
latLngToTile = (lat, lng, zoom) ->
  NUM_OF_TILES = 2 ** zoom
  LNG_DEGREES_PER_TILE = 360 / NUM_OF_TILES

  sinLat = Math.sin(lat * Math.PI / 180)

  x = (lng + 180) / LNG_DEGREES_PER_TILE
  y = (0.5 + -0.5 * Math.log((1 + sinLat) / (1 - sinLat)) / (2 * Math.PI)) * NUM_OF_TILES
  {x, y}


tileTolatLng = (x, y, zoom=14) ->
  x /= 2 ** zoom
  y /= 2 ** zoom

  lng = (x - (1 / 2)) / (1 / 360)
  latRadians = (y - (1 / 2)) / -(1 / (2 * Math.PI))
  lat = (2 * Math.atan(Math.exp(latRadians)) - Math.PI / 2) / Math.PI * 180

  {latitude: lat, longitude: lng}


latLngToWorld = (lat, lng) ->
  METERS_PER_DEGREE = 40000 * 1000 / 360

  # x: (lng + 180) * METERS_PER_DEGREE, // 酷いブレ
  x = (lng) * METERS_PER_DEGREE
  y = (90 - lat) * METERS_PER_DEGREE
  {x, y}


getTileCord = ({x, y, latitude, longitude}) ->
  zoom = 14
  tile =
    if x? && y?
      {x, y}
    else
      latLngToTile latitude, longitude, zoom

  {x: ~~tile.x, y: ~~tile.y}


buildGroundMesh = ({roughness, x, y, latitude, longitude}) ->
  zoom = 14
  roughness ||= 0
  tileCord = getTileCord {x, y, latitude, longitude}

  factor = 2 ** roughness
  xlength = 256 / factor
  ylength = 256 / factor

  # 日本程度の緯度の場合、ズームレベル14のタイル1枚の縦横の長さは
  # だいたい1700mぐらいになる
  geometry = new THREE.PlaneGeometry(
    1.7 * 1000, 1.7 * 1000,
    xlength - 1,
    ylength - 1
  )

  targetPath = [
    "data"
    "dem"
    zoom
    tileCord.x
    tileCord.y + ".txt"
  ].join("/")

  dem = loadText(targetPath)
    .split("\n").map (row) ->
      row.split(",").map (height) ->
        parseFloat(height) || -1

  for y in [0..(xlength - 1)]
    for x in [0..(ylength - 1)]
      vertex = geometry.vertices[x + (y * xlength)]
      vertex.z = dem[y * factor][x * factor]


  imagePath = [
    "data"
    "relief"
    zoom
    tileCord.x
    tileCord.y + ".png"
  ].join("/")

  geometry.computeFaceNormals()
  geometry.computeVertexNormals()
  new THREE.Mesh geometry,
    new THREE.MeshBasicMaterial
      map: THREE.ImageUtils.loadTexture(imagePath)

class GroundMeshLoader
  constructor: ->
    @grounds = {}

  # TODO: ロードと配置の処理は分けるべき。Google Maps の MapTypes みたいに
  load: (opts) ->
    tileCord = getTileCord(opts)
    tileLatLng = tileTolatLng(tileCord.x, tileCord.y)
    worldCord = latLngToWorld(tileLatLng.latitude, tileLatLng.longitude)
    ground = buildGroundMesh(opts)
    ground.rotation.x = Math.PI / -2
    ground.position.x = worldCord.x
    ground.position.z = worldCord.y
    @setGround tileCord.x, tileCord.y, ground
    ground

  setGround: (x, y, ground) ->
    @grounds[x + "," + y] = ground
    return

  getGround: (x, y) ->
    @grounds[x + "," + y]
