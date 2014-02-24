do (root=window) ->
  root.Geo = class Geo
    @utils: {
    }

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
        node({n},{w},{s},{e});
        <;
      );
      (node(w); <;);
      out;
      """,
      (url) -> Q.nfcall d3.json, url

    @_overpass: new Resouce \
      ->,
      -> Q.fulfill data
