do (root=window) ->
  root.Geo = class Geo
    @utils: {
    }

  Geo.Layer = class Layer
    resouces: []
    loadResouces: (params...) ->
      Q.all @resouces.map (resouce, i) ->
        resouce.load params[i]


  Geo.Resouce = class Resouce
    constructor: (@template, @loadfn) ->
      if _.isString @template
        template = @template
        @template = (params) ->
          template.replace /\{([nwsexyz])\}/g, (match, key) -> params[key]

    load: (params) ->
      url = @template params
      @loadfn url


    @overpass: new Resouce \
      """
      http://overpass-api.de/api/interpreter?data=\
      [out:json];
      (
        node({s},{w},{n},{e});
        way(bn);
      );
      (
        ._;
        node(w);
      );
      out;
      """,
      (url) -> Q.nfcall d3.json, url

    @_overpass: new Resouce \
      ->,
      -> Q.fulfill data



    parseDemCsv = (text) ->
      d3.csv.parseRows(text).map (row) ->
        row.map (height) ->
          parseFloat(height) || -1
    do ->
      THREE.ImageUtils.crossOrigin = '*'

    @dem: new Resouce \
      'http://cyberjapandata.gsi.go.jp/xyz/dem/{z}/{x}/{y}.txt',
      (url) ->
        Q.nfcall d3.text, url
          .then parseDemCsv

    @_dem: new Resouce \
      "data/dem/{z}/{x}/{y}.txt",
      (url) ->
        Q.nfcall d3.text, url
          .then parseDemCsv

    @relief: new Resouce \
      'http://cyberjapandata.gsi.go.jp/xyz/relief/{z}/{x}/{y}.png',
      (url) -> Q.fulfill THREE.ImageUtils.loadTexture url

    @_relief: new Resouce \
      "data/relief/{z}/{x}/{y}.png",
      (url) -> Q.fulfill THREE.ImageUtils.loadTexture url

    @pale: new Resouce \
      'http://cyberjapandata.gsi.go.jp/xyz/pale/{z}/{x}/{y}.png',
      (url) -> Q.fulfill THREE.ImageUtils.loadTexture url

