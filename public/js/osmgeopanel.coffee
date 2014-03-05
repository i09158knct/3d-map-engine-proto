do ->

  toAssoc = (elems) ->
    acc =
      node: {}
      way: {}
      relation: {}

    elems.forEach (elem) ->
      acc[elem.type][elem.id] = elem

    acc



  # data schema
    # "version": 0.6,
    # "generator": "Overpass API",
    # "osm3s": {
    #   "timestamp_osm_base": "2014-02-23T06:38:02Z",
    #   "copyright": "The data included in this document is from www.openstreetmap.org. The data is made available under ODbL."
    # },
    # "elements": [
    #   ...
    # ]
  parseData = (overpassData) ->
    toAssoc overpassData.elements


  # data schema
    # node:
    #   type: "node"
    #   id: 2661538120
    #   lat: 50.7479041
    #   lon: 7.1555298
    #   tags: {}
    # way:
    #   type: "way"
    #   id: 105196617
    #   nodes: [
    #     2661538120
    #     ...
    #   ]
    #   tags:
    #     building: "yes"
    # relation:
    #   id: 2323
    #   members:
    #     ref: 238669065
    #     type: "way"
    #     role: "outer"
    #   tags: {}
  getNodes = (assoc, way) ->
    way.nodes.map (id) ->
      assoc.node[id]

  getMembers = (assoc, rel) ->
    # Note: roleも返すべき？
    rel.members.map (member) ->
      type = member.type
      id = member.ref
      assoc[type][id]

  isArea = (way) ->
    first = _.first way.nodes
    last = _.last way.nodes
    first == last


  window.midpoint = ([x1, y1], [x2, y2]) ->
    x = x1 - (x1 - x2) / 2
    y = y1 - (y1 - y2) / 2
    [x, y]

  window.centroid = (boundary) ->
    p1 = [boundary.w, boundary.n]
    p2 = [boundary.e, boundary.s]
    midpoint p1, p2


  # via Vizicities and
  # https://developers.google.com/maps/documentation/javascript/examples/map-coordinates
  window.lonlatToTile = (lon, lat, zoom, isFloat=false) ->
    numOfTiles = 2 ** zoom
    lonDegreesPerTile = 360 / numOfTiles
    sinLat = Math.sin(lat * Math.PI / 180)
    tx = (lon + 180) / lonDegreesPerTile
    ty = (0.5 + -0.5 * Math.log((1 + sinLat) / (1 - sinLat)) / (2 * Math.PI)) * numOfTiles
    if isFloat
      [tx, ty]
    else
      [Math.floor(tx), Math.floor(ty)]

  window.tileTolonlat = (tx, ty, zoom) ->
    numOfTiles = 2 ** zoom
    tx %= numOfTiles
    ty %= numOfTiles # 間違った正規化？
    x = tx / numOfTiles
    y = ty / numOfTiles

    lon = (x - (1 / 2)) / (1 / 360)
    latRadians = (y - (1 / 2)) / -(1 / (2 * Math.PI))
    lat = (2 * Math.atan(Math.exp(latRadians)) - Math.PI / 2) / Math.PI * 180
    [lon, lat]



  window.tileToBoundary = (x, y, zoom) ->
    p1 = tileTolonlat x, y, zoom
    p2 = tileTolonlat x+1, y+1, zoom
    {
      n: p1[1]
      w: p1[0]
      s: p2[1]
      e: p2[0]
    }


  class OverpassObjectManager
    # objects:

    constructor: ->



  class OverpassRenderer
    lonlatAsArray = ({lon, lat}) -> [lon, lat]
    xyAsVec3 = ([x, y]) -> new THREE.Vector3 x, y, 0

    materialOptions:
      railway:
        platform:
          color: 0x555500
          amount: 10

        rail:
          color: 0xffff00
          linewidth: 1

      highway:
        pedestrian:
          color: 0x00cccc
          amount: 1
        primary:
          color: 0xffaa555
          linewidth: 1000
          # fog: true

        secondary:
          color: 0xaa5500
          linewidth: 5
          # fog: true

        residential:
          color: 0xffffff
          linewidth: 2
          # fog: true

        default:
          color: 0xcccccc
          linewidth: 1
          # fog: true

      waterway:
        default:
          color: 0x0000ff
          linewidth: 10
          # fog: true

      amenity:
        school:
          color: 0x00aa00
          amount: 1000
        theatre:
          color: 0xcc5500
          amount: 50
        parking:
          color: 0xffffaa
          amount: 1
        bus_station:
          color: 0xcc0000
          amount: 10
        default:
          color: 0xffffff
          amount: 100

      building:
        commercial:
          color: 0x5555cc
          amount: 50
        yes:
          color: 0x888888
          amount: 25
          vertexColors: THREE.VertexColors
        default:
          color: 0xffffff
          amount: 1

      natural:
        wood:
          color: 0x00ff00
          amount: 50
        water:
          color: 0x0000cc
          amount: 5
        default:
          color: 0x00ff00
          amount: 1000

      leisure:
        pitch:
          color: 0xcc5500
          amount: 5
        golf_course:
          color: 0x00cc55
          amount: 5
        default:
          color: 0x00cc55
          amount: 1000

      landuse:
        forest:
          color: 0x00ff00
          amount: 100
        old_forest:
          color: 0x005500
          amount: 100
        default:
          color: 0x005500
          amount: 500

    constructor: (@project, materialOptions={}) ->
      _.extend @materialOptions, materialOptions
      @root = new THREE.Object3D();
      @root.rotation.x = 90 * Math.PI / 180
      @root.scale.z = -1

    nodeToXy: (node) -> @project lonlatAsArray node
    nodeToVec3: (node) -> xyAsVec3 @nodeToXy node

    createFloor: (boundary) ->
      nodes = [
        {lon: boundary.w, lat: boundary.n}
        {lon: boundary.w, lat: boundary.s}
        {lon: boundary.e, lat: boundary.s}
        {lon: boundary.e, lat: boundary.n}
      ]

      shape = @createShape nodes
      geometry = shape.extrude
        amount: 1
        bevelEnabled: false

      floor = new THREE.Mesh \
        geometry,
        new THREE.MeshBasicMaterial
          color: 0x333333
      floor.position.z = -120
      @root.add floor
      floor



    findMaterialOptions: (tags={}) ->
      mkeys = _.keys @materialOptions
      tkeys = _.keys tags
      key = _.first _.intersection mkeys, tkeys
      if key?
        category = @materialOptions[key]
        tvalue = tags[key]
        category[tvalue] ? category.default
      else
        null

    process: (data) ->
      @assoc = parseData data
      # points = @processPoints()
      points = []
      lines = @processLines()
      polygons = @processPolygons()

    processPoints: ->
      _.each @assoc.node, (node) =>
        @root.add @createPoint node, 0xffff00

    processLines: ->
      ways = _.filter @assoc.way, (way) -> !isArea(way)
      _.each ways, (way) =>
        opts = @findMaterialOptions way.tags
        @root.add @createLine way, opts

    processPolygons: ->
      areas = _.filter @assoc.way, isArea
      _.each areas, (area) =>
        opts = @findMaterialOptions area.tags
        @root.add @createPolygon area, opts

    createPoint: (node, color=0xff0000) ->
      point =  new THREE.Mesh \
        new THREE.SphereGeometry(5),
        new THREE.MeshBasicMaterial(color: color)

      point.position = @nodeToVec3 node
      point

    createShape: (nodes) =>
      shape = new THREE.Shape()
      shape.moveTo @nodeToXy(nodes[0])...
      nodes.slice(1).forEach (node) =>
        shape.lineTo @nodeToXy(node)...

      shape


    createLine: (way, opts) ->
      createWay = (way) =>
        nodes = getNodes @assoc, way
        geometry = new THREE.Geometry()
        geometry.vertices = nodes.map (node) =>
          @nodeToVec3 node

        geometry

      line = new THREE.Line \
        createWay(way),
        new THREE.LineBasicMaterial opts


    createPolygon: (area, opts={color: 0xffffff, opacity: 0.8, transparent: true}) ->
      createBuilding = (area, opts) =>
        nodes = getNodes @assoc, area
        shape = @createShape nodes
        geometry = shape.extrude _.defaults opts,
          amount: 5
          bevelEnabled: false
          # material: undefined
          # extrudeMaterial: undefined
        geometry.computeFaceNormals()
        geometry


      poly = new THREE.Mesh \
        createBuilding(area, opts),
        # new THREE.MeshBasicMaterial opts
        new THREE.MeshLambertMaterial _.defaults opts,
          side: THREE.BackSide


    createTihyo: (boundary, dem, mapimage) ->
      xlength = dem[0].length
      ylength = dem.length
      lonDegreesPerSegment = (boundary.e - boundary.w) / xlength
      latDegreesPerSegment = (boundary.n - boundary.s) / ylength

      geometry = new THREE.PlaneGeometry \
        0, 0, # initial geometry size
        xlength - 1, ylength - 1 # segments

      dem.forEach (row, yindex) =>
        row.forEach (height, xindex) =>
          lon = boundary.w + lonDegreesPerSegment * xindex
          lat = boundary.n - latDegreesPerSegment * yindex
          [x, y] = @project [lon, lat]
          vertex = geometry.vertices[xindex + (yindex * xlength)]
          vertex.x = x
          vertex.y = y
          vertex.z = dem[yindex][xindex]

      geometry.computeFaceNormals()
      geometry.computeVertexNormals()
      window.tihyo = new THREE.Mesh \
        geometry,
        new THREE.MeshBasicMaterial
          map: mapimage
          opacity: 0.9
          transparent: true
          # side: THREE.DoubleSide
          # side: THREE.BackSide

      tihyo.position.z = -10
      tihyo.position.z = -945
      @root.add tihyo
      tihyo

  # (x, y) ->
  #   [segmentWidth, segmentHeight] = do ->
  #     f = _.first verteceis
  #     l = _.last verteceis
  #     width = f.x - l.x
  #     height = f.y - l.y
  #     [width / xlength, height / ylength]



  window.OverpassLayer = class OverpassLayer extends Geo.Layer
    # Q.allがkey-value likeなオブジェクトを受け付けないので、
    # 配列を使う必要がある
    resouces: [
      Geo.Resouce.overpass
      Geo.Resouce.dem
      Geo.Resouce.relief
      # Geo.Resouce._overpass
      # Geo.Resouce._dem
      # Geo.Resouce._relief
    ]

    overpassData: {}
    panels: []
    elements:
      node: {}
      way: {}
      relation: {}

    constructor: ({@scene, center}) ->
      @project = d3.geo.mercator()
        # .scale 10 * 100000
        .scale 65 * 100000
        .center center
        .translate [0, 0]

      @renderer = new OverpassRenderer @project

    clear: ->
      objs = _.rest @renderer.root.children, 1
      _.each objs, (obj) =>
        @renderer.root.remove obj

    createPanel: (tile) ->
      window.boundary = tileToBoundary tile.x, tile.y, tile.z
      @scene.add @renderer.root
      # @renderer.createFloor boundary
      @loadResouces boundary, tile, tile
        .spread (data, dem, mapimage) =>
          @renderer.createTihyo boundary, dem, mapimage
          @renderer.process data
