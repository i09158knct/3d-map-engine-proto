(function(root) {
  var Geo, Resouce;
  root.Geo = Geo = (function() {
    function Geo() {}

    Geo.utils = {};

    return Geo;

  })();
  return Geo.Resouce = Resouce = (function() {
    function Resouce(template, loadfn) {
      this.template = template;
      this.loadfn = loadfn;
      if (_.isString(this.template)) {
        template = this.template;
        this.template = function(params) {
          return template.replace(/\{([nwsexyz])\}/g, function(match, key) {
            return params[key];
          });
        };
      }
    }

    Resouce.prototype.load = function(params) {
      var url;
      url = this.template(params);
      return this.loadfn(url);
    };

    Resouce.overpass = new Resouce("http://overpass-api.de/api/interpreter?data=[out:json];\n(\n  node({n},{w},{s},{e});\n  <;\n);\n(node(w); <;);\nout;", function(url) {
      return Q.nfcall(d3.json, url);
    });

    Resouce._overpass = new Resouce(function() {}, function() {
      return Q.fulfill(data);
    });

    return Resouce;

  })();
})(window);
