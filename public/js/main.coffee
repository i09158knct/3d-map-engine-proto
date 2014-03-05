$ ->

  # シーン
  # ====================
  window.scene = new THREE.Scene()
  # scene.fog = new THREE.Fog(0xeeeeff, 100, 1500 * 5)



  # レンダラー
  # ====================
  renderer = new THREE.WebGLRenderer()
  renderer.setSize window.innerWidth, window.innerHeight
  document.getElementById 'container'
    .appendChild renderer.domElement

  # renderer.gammaInput = true
  # renderer.gammaOutput = true
  # renderer.physicallyBasedShading = true
  # renderer.shadowMapEnabled = true
  # renderer.shadowMapSoft = true



  # 光源
  # ====================
  # window.light = new THREE.AmbientLight(0x555555)
  # scene.add light

  window.directionalLight = new THREE.DirectionalLight(0xffffffff, 1)
  directionalLight.position.set 1000, -10000, 750
  scene.add directionalLight

  window.directionalLight2 = new THREE.DirectionalLight(0xffffffff, 0.3)
  directionalLight2.position.set -1000, -1000, -750
  scene.add directionalLight2

  window.directionalLight3 = new THREE.DirectionalLight(0xffffffff, 1)
  directionalLight3.position.set 1000, 1000, 750
  scene.add directionalLight3


  # 大気
  # ====================
  # atmospere = new THREE.Mesh \
  #   new THREE.SphereGeometry(5000, 60, 49),
  #   new THREE.MeshBasicMaterial(color: 0xeeeeff)
  # atmospere.scale.x = -1
  # scene.add atmospere



  # 四角形
  # ====================
  window.cube = new THREE.Mesh \
    new THREE.CubeGeometry(10, 10, 10),
    new THREE.MeshBasicMaterial(color: 0x00ff00)
  cube.position.set 0, 0, 0
  scene.add cube



  # カメラ・コントロール
  # ====================
  camera = new THREE.PerspectiveCamera \
    70,
    window.innerWidth / window.innerHeight,
    1,
    30 * 1000

  scene.add camera
  controls = new THREE.TrackballControls camera, renderer.domElement
  camera.position.set 1000, 1000, 1000
  camera.position.add cube.position
  controls.target = cube.position

  window.moveStates =
    left: false
    right: false
    up: false
    down: false



  updateCamera = ->
    if moveStates.left
      camera.position.x -= 20
      controls.target.x -= 20
    if moveStates.right
      camera.position.x += 20
      controls.target.x += 20
    if moveStates.up
      camera.position.z -= 20
      controls.target.z -= 20
    if moveStates.down
      camera.position.z += 20
      controls.target.z += 20

  render = ->
    controls.update()
    updateCamera()
    renderer.render scene, camera


  requestAnimationFrame animate = ->
    requestAnimationFrame animate
    render() if !window.isStoping



  class ControllerViewModel
    constructor: ({scene, target}) ->
      boundary = tileToBoundary target.x, target.y, target.z
      center = centroid boundary
      @mainlayer = new OverpassLayer({scene, center})

      @tileLocation =
        lon: ko.observable center[0]
        lat: ko.observable center[1]

      getTile = =>
        lon = +@tileLocation.lon()
        lat = +@tileLocation.lat()
        z = +(@tile?.z?() ? target.z)
        [x, y] = lonlatToTile lon, lat, z
        {x, y, z}

      getTileCentroid = (x, y, z) ->
        boundary = tileToBoundary +x, +y, +z
        [lon, lat] = centroid boundary


      @tile =
        x: ko.computed
          read: => getTile().x
          write: (x) =>
            x = +x
            {_x, y, z} = getTile()
            [lon, lat] = getTileCentroid x, y, z
            @tileLocation.lon lon
        y: ko.computed
          read: => getTile().y
          write: (y) =>
            y = +y
            {x, _y, z} = getTile()
            [lon, lat] = getTileCentroid x, y, z
            @tileLocation.lat lat
        z: ko.observable target.z

      @boundary =
        s: ko.observable()
        w: ko.observable()
        n: ko.observable()
        e: ko.observable()

      _centerLon = ko.observable(center.lon ? center[0])
      _centerLat = ko.observable(center.lat ? center[1])
      @center =
        lon: ko.computed
          read: -> _centerLon()
          write: (lon) => _centerLon +lon; @updateCenter()
        lat: ko.computed
          read: -> _centerLat()
          write: (lat) => _centerLat +lat; @updateCenter()

      @isStoping = ko.observable()


    stop: -> window.isStoping = true; @isStoping true
    start: -> window.isStoping = false; @isStoping false

    updateCenter: ->
      lon = +@center.lon()
      lat = +@center.lat()
      @mainlayer.project =
        @mainlayer.project.center [lon, lat]
      @mainlayer.renderer.project =
        @mainlayer.renderer.project.center [lon, lat]


    loadTile: ->
      tile =
        x: +@tile.x()
        y: +@tile.y()
        z: +@tile.z()
      @load tile

    loadBoundary: ->
      boundary = ko.toJS @boundary
      tile = boundaryToTile boundary
      @load tile

    load: (tile) ->
      console.log 'loading', tile

      @mainlayer.createPanel tile
        .then -> console.log 'rendered', tile
        .fail (err) ->
          window.err = err
          console.error err.stack


    removeAll: ->
      @mainlayer.clear()




  window.tp =
    x: 14271
    y: 6531
    z: 14
  window.tp2 =
    x: 14501
    y: 6414
    z: 14

  window.target = tp2
  window.vm = new ControllerViewModel({scene, target})
  ko.applyBindings vm
  vm.load target
  # setTimeout stop, 10000
