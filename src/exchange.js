var entities, entity, id, _fn,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

window.WarpExchange = {
  capture_id: 0,
  captures: {},
  capture: function(ids) {
    this.captures[this.capture_id] = {
      ids: ids,
      done: false,
      values: {}
    };
    return this.capture_id++;
  },
  release: function(cid) {
    return delete this.captures[cid];
  }
};

entities = window.app.warp_client.entities;

_fn = (function(_this) {
  return function(id) {
    return entity.link.onvalue.add(function(value) {
      var capture, captures, _, _results;
      captures = window.WarpExchange.captures;
      _results = [];
      for (_ in captures) {
        capture = captures[_];
        if (__indexOf.call(capture.ids, id) >= 0) {
          if (capture.values[id] == null) {
            capture.values[id] = value;
            if (Object.keys(capture.values === capture.ids.length)) {
              _results.push(capture.done = true);
            } else {
              _results.push(void 0);
            }
          } else {
            _results.push(void 0);
          }
        }
      }
      return _results;
    });
  };
})(this);
for (id in entities) {
  entity = entities[id];
  _fn(id);
}
