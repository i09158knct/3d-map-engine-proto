var __slice = [].slice;

(function(root) {
  var Geo, Layer, Resouce;
  root.Geo = Geo = (function() {
    function Geo() {}

    Geo.utils = {};

    return Geo;

  })();
  Geo.Layer = Layer = (function() {
    function Layer() {}

    Layer.prototype.resouces = [];

    Layer.prototype.loadResouces = function() {
      var params;
      params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return Q.all(this.resouces.map(function(resouce, i) {
        return resouce.load(params[i]);
      }));
    };

    return Layer;

  })();
  return Geo.Resouce = Resouce = (function() {
    var parseDemCsv;

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

    Resouce.overpass = new Resouce("http://overpass-api.de/api/interpreter?data=[out:json];\n(\n  node({s},{w},{n},{e});\n  way(bn);\n);\n(\n  ._;\n  node(w);\n);\nout;", function(url) {
      return Q.nfcall(d3.json, url);
    });

    Resouce._overpass = new Resouce(function() {}, function() {
      return Q.fulfill(data);
    });

    parseDemCsv = function(text) {
      return d3.csv.parseRows(text).map(function(row) {
        return row.map(function(height) {
          return parseFloat(height) || -1;
        });
      });
    };

    (function() {
      return THREE.ImageUtils.crossOrigin = '*';
    })();

    Resouce.dem = new Resouce('http://cyberjapandata.gsi.go.jp/xyz/dem/{z}/{x}/{y}.txt', function(url) {
      return Q.nfcall(d3.text, url).then(parseDemCsv);
    });

    Resouce._dem = new Resouce("data/dem/{z}/{x}/{y}.txt", function(url) {
      return Q.nfcall(d3.text, url).then(parseDemCsv);
    });

    Resouce.relief = new Resouce('http://cyberjapandata.gsi.go.jp/xyz/relief/{z}/{x}/{y}.png', function(url) {
      return Q.fulfill(THREE.ImageUtils.loadTexture(url));
    });

    Resouce._relief = new Resouce("data/relief/{z}/{x}/{y}.png", function(url) {
      return Q.fulfill(THREE.ImageUtils.loadTexture(url));
    });

    return Resouce;

  })();
})(window);
