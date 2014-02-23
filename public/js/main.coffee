$ ->

  # なにか
  # ====================
  gLoader = new GroundMeshLoader()



  # シーン
  # ====================
  scene = new THREE.Scene()
  # scene.fog = new THREE.Fog(0xeeeeff, 100, 1500)



  # 地表
  # ====================
  ground = gLoader.load
    roughness: 0
    x: 14271
    y: 6531
    # latitude: 34.25501725339201
    # longitude: 133.58739852905273

  # ground = new THREE.Mesh(
  #   new THREE.PlaneGeometry(
  #     1.7 * 1000,
  #     1.7 * 1000,
  #     2, 2
  #   ),
  #   new THREE.MeshBasicMaterial(color: 0xff00ff)
  # )
  # ground.position.y = 0
  # ground.rotation.x = Math.PI / -2

  scene.add(ground)



  # 大気
  # ====================
  # atmospere = new THREE.Mesh(
  #   new THREE.SphereGeometry(500, 60, 49),
  #   new THREE.MeshBasicMaterial(color: 0xeeeeff)
  # )
  # atmospere.scale.x = -1
  # scene.add(atmospere)



  # 四角形
  # ====================
  cube = new THREE.Mesh(
    new THREE.CubeGeometry(1, 1, 1),
    new THREE.MeshBasicMaterial(color: 0x00ff00)
  )
  cube.position = new THREE.Vector3(0, 0, 0)
  cube.position.add(ground.position)

  scene.add(cube)



  # レンダラー
  # ====================
  renderer = new THREE.WebGLRenderer()
  renderer.setSize(window.innerWidth, window.innerHeight)
  document.getElementById("container").appendChild(renderer.domElement)



  # カメラ・コントロール
  # ====================
  camera = new THREE.PerspectiveCamera(
    70,
    window.innerWidth / window.innerHeight,
    1,
    30 * 1000
  )
  scene.add(camera)
  controls = new THREE.TrackballControls(camera, renderer.domElement)
  camera.position = new THREE.Vector3(1000, 1000, 1000)
  camera.position.add(cube.position)
  controls.target = cube.position

  moveStates =
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
    renderer.render(scene, camera)


  requestAnimationFrame animate = ->
    requestAnimationFrame(animate)
    render()

  ControllerView = Backbone.View.extend(
    el: "#controller"
    events:
      "mousedown .goLeft": "goLeft"
      "mousedown .goRight": "goRight"
      "mousedown .goUp": "goUp"
      "mousedown .goDown": "goDown"
      "mouseup .go": "stop"

    goLeft: ->
      moveStates.left = true
      return

    goRight: ->
      moveStates.right = true
      return

    goUp: ->
      moveStates.up = true
      return

    goDown: ->
      moveStates.down = true
      return

    stop: ->
      moveStates.left = false
      moveStates.right = false
      moveStates.up = false
      moveStates.down = false
      return
  )
  window.views = controller: new ControllerView()
