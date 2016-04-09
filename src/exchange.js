var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

window.WarpExchange = {
  received: {},
  done: false,
  capture: function(ids) {
    var entities, entity, id, results;
    entities = window.app.warp_client.entities;
    results = [];
    for (id in entities) {
      entity = entities[id];
      if (indexOf.call(ids, id) >= 0) {
        results.push((function(_this) {
          return function(id) {
            return entity.link.onvalue.add((function(value) {
              _this.received[id] = value;
              entities[id].link.onvalue.remove('capture');
              if (Object.keys(_this.received === ids.length)) {
                return _this.done = true;
              }
            }), 'capture');
          };
        })(this)(id));
      }
    }
    return results;
  },
  reset: function() {
    this.received = {};
    return this.done = false;
  }
};
