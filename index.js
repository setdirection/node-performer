require("coffee-script");

fs = require("fs");

module.exports = exports = require("./lib/performer.coffee");

exports.plugins = {};

/*
 * Load all bundled plugins on demand.
 */
fs.readdirSync(__dirname + '/lib/plugins').forEach(function(filename){
  if (/\.(coffee|js)$/.test(filename)) {
    var name = filename.substr(0, filename.lastIndexOf('.'));
    exports.plugins.__defineGetter__(name, function(){
      return require('./lib/plugins/' + filename);
    });
  }
});
