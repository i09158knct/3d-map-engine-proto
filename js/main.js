$(function() {
  var animate, camera, controls, cube, moveStates, render, renderer, updateCamera;
  window.scene = new THREE.Scene();
  renderer = new THREE.WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.getElementById("container").appendChild(renderer.domElement);
  cube = new THREE.Mesh(new THREE.CubeGeometry(10, 10, 10), new THREE.MeshBasicMaterial({
    color: 0x00ff00
  }));
  cube.position = new THREE.Vector3(0, 0, 0);
  scene.add(cube);
  camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 30 * 1000);
  scene.add(camera);
  controls = new THREE.TrackballControls(camera, renderer.domElement);
  camera.position = new THREE.Vector3(1000, 1000, 1000);
  camera.position.add(cube.position);
  controls.target = cube.position;
  moveStates = {
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
  window.stop = function() {
    return window._stop = true;
  };
  window.start = function() {
    return window._stop = false;
  };
  return requestAnimationFrame(animate = function() {
    requestAnimationFrame(animate);
    if (!window._stop) {
      return render();
    }
  });
});
