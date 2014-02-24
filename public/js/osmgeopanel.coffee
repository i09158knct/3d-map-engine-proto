# panel = new GeoPanel
#   n: 50.74599093970515
#   w: 7.153891324996948
#   s: 50.747956248259705
#   e: 7.156493067741394

do (root=window) ->
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


  root.tPoints =
    n: 50.74599093970515
    w: 7.153891324996948
    s: 50.747956248259705
    e: 7.156493067741394
  tPoints.p1 = [tPoints.n, tPoints.w]
  tPoints.p2 = [tPoints.s, tPoints.e]

  root.latScale = d3.scale.linear()
    .domain [tPoints.p1[0], tPoints.p2[0]]
    .range [-500, 500]

  root.lonScale = d3.scale.linear()
    .domain [tPoints.p1[1], tPoints.p2[1]]
    .range [-500, 500]

  root.project = (node) ->
    [
      latScale node.lat
      lonScale node.lon
    ]


  createPoint = (node, color=0xff0000) ->
    point =  new THREE.Mesh \
      new THREE.SphereGeometry(5),
      new THREE.MeshBasicMaterial(color: color)
    point.position = new THREE.Vector3(latScale(node.lat), 0, lonScale(node.lon))
    point


  createFloor = ->
    floor = new THREE.Mesh \
      new THREE.PlaneGeometry(1000, 1000),
      new THREE.MeshBasicMaterial
        color: 0x333333
    floor.rotation.x = -90 * Math.PI / 180
    floor.position.y = -0.5
    floor

  createShape = (way, nodes) ->
    shape = new THREE.Shape()

    shape.moveTo project(nodes[0])...
    nodes.slice(1).forEach (node) ->
      shape.lineTo project(node)...

    shape


  createBuilding = (assoc, area) ->
    nodes = getNodes assoc, area
    shape = createShape area, nodes
    geometry = shape.extrude
      amount: -100
      bevelEnabled: false
      material: undefined
      extrudeMaterial: undefined

  createWay = (assoc, way) ->
    nodes = getNodes assoc, way
    geometry = new THREE.Geometry()

    # Note: compact
    geometry.vertices = _.compact(nodes).map (node) ->
      new THREE.Vector3(latScale(node.lat), lonScale(node.lon), 0)
    geometry

  class Panel
    floor: null
    objects:
      point: {}
      line: {}
      poly: {}

    materialOptions:
      highway:
        primary:
          color: 0xff0000
          linewidth: 1000
          # fog: true

        residential:
          color: 0xffffff
          linewidth: 2
          # fog: true

        default:
          color: 0xff0000
          linewidth: 1
          # fog: true

      waterway:
        default:
          color: 0x0000ff
          linewidth: 10
          # fog: true

      amenity:
        default:
          color: 0x00ffff

      building:
        yes:
          color: 0xcccccc
        default:
          color: 0x00ff00


    constructor: (data) ->
      @assoc = parseData data
      @initFloor()
      @initPoints()
      @initOthers()


    initFloor: ->
      @floor = @createFloor tPoints

    initPoints: ->
      _.each @assoc.node, (node, id) =>
        point = @createPoint node, 0xffff00
        @objects.point[id] = point

    initOthers: ->
      _.each @assoc.way, (way, id) =>
        # console.log(way.type, way.tags);
        opts = @findMaterialOptions way.tags

        if isArea way
          console.log way.tags
          @addPolygon id, way, opts

        else if opts?
          @addLine id, way, opts
          # console.log 'highway', way.tags

    findMaterialOptions: (tags) ->
      mkeys = _.keys @materialOptions
      tkeys = _.keys tags
      key = _.first _.intersection mkeys, tkeys
      if key?
        category = @materialOptions[key]
        tvalue = tags[key]
        category[tvalue] ? category.default
      else
        null

    allObjects: ->
      [
        [@floor]...
        (_.values @objects.point)...
        (_.values @objects.line)...
        (_.values @objects.poly)...
      ]

    createPoint: createPoint
    createFloor: createFloor
    createWay: (way) ->
      createWay @assoc, way

    createBuilding: (area) ->
      createBuilding @assoc, area

    addLine: (id, way, opts) ->
      line = new THREE.Line \
        @createWay(way),
        new THREE.LineBasicMaterial opts
      line.rotation.x = 90 * Math.PI / 180
      @objects.line[id] = line

    addPolygon: (id, area, opts) ->
      poly = new THREE.Mesh \
        @createBuilding(area),
        new THREE.MeshBasicMaterial opts

      poly.rotation.x = 90 * Math.PI / 180
      @objects.poly[id] = poly




  root.OpenpassLayer = class OpenpassLayer
    # Q.allがkey-value likeなオブジェクトを受け付けないので、
    # 配列を使う必要がある
    resouces: [
      Geo.Resouce.overpass
      # Geo.Resouce._overpass
    ]
    panels: []
    elements:
      node: {}
      way: {}
      relation: {}

    constructor: ->

    loadResouces: (params...) ->
      Q.all @resouces.map (resouce, i) ->
        resouce.load params[i]

    createPanel: (params...) ->
      @loadResouces params...
        .then (ress) => new Panel(ress[0])
        .then (panel) => @panel = panel
        .then -> console.log 'done'
        .fail -> (err) -> window.err = err



    @utils: {
      toAssoc
    }

  window.a = new OpenpassLayer()
  $ ->
    a.createPanel(tPoints).then ->
      _.each a.panel.allObjects(), (obj) -> scene.add obj
      # setTimeout stop, 10000
