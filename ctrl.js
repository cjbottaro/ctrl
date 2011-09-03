(function() {
  var Ctrl, myTimeout;
  var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  myTimeout = function(msg, time, callback) {
    return setTimeout(function() {
      return callback(msg, time);
    }, time);
  };
  Ctrl = (function() {
    function Ctrl() {}
    Ctrl["new"] = function() {
      var ctrl, steps;
      steps = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      ctrl = new Ctrl;
      if (steps.length > 0) {
        ctrl.exec.apply(ctrl, steps);
      }
      return ctrl;
    };
    Ctrl.prototype.exec = function() {
      var steps;
      steps = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.steps = steps;
      this.index = 0;
      this.i_results = [];
      this.n_results = [];
      return this.run_steps();
    };
    Ctrl.prototype.run_steps = function() {
      var step, _results;
      _results = [];
      while (true) {
        step = this.steps[this.index];
        if (step == null) {
          break;
        }
        this.call(step);
        if (this.defers > 0) {
          break;
        }
        _results.push(this.index += 1);
      }
      return _results;
    };
    Ctrl.prototype.call = function(step) {
      this.defers = 0;
      this.calls = 0;
      this.i_results[this.index] = [];
      this.n_results[this.index] = {};
      this.expose_previous_results();
      return step(this);
    };
    Ctrl.prototype.expose_previous_results = function() {
      var result, results;
      if (this.index === 0) {
        this.result = null;
        this.results = [];
        this.named_results = {};
        return;
      }
      results = (function() {
        var _i, _len, _ref, _results;
        _ref = this.i_results[this.index - 1];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          result = _ref[_i];
          if (result != null) {
            _results.push(result);
          }
        }
        return _results;
      }).call(this);
      if (results != null) {
        this.result = results[0];
        if (this.result.length === 1) {
          this.result = this.result[0];
        }
        this.results = results;
      } else {
        this.result = null;
        this.results = [];
      }
      results = this.n_results[this.index - 1];
      if (results != null) {
        return this.named_results = results;
      } else {
        return this.named_results = {};
      }
    };
    Ctrl.prototype.collect = function() {
      var index, names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      index = this.defers;
      this.defers += 1;
      return __bind(function() {
        var name, result, results, _i, _len, _ref, _ref2;
        results = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (names.length > 0) {
          _ref = this.zip(names, results);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            _ref2 = _ref[_i], name = _ref2[0], result = _ref2[1];
            this.n_results[this.index][name] = result;
          }
        } else {
          this.i_results[this.index][index] = results;
        }
        this.calls += 1;
        if (this.calls === this.defers) {
          this.index += 1;
          return this.run_steps();
        }
      }, this);
    };
    Ctrl.prototype.zip = function(ar1, ar2) {
      var i, zipped;
      zipped = [];
      i = 0;
      while (i < ar1.length) {
        zipped[i] = [ar1[i], ar2[i]];
        i += 1;
      }
      if (ar2.length > ar1.length) {
        i -= 1;
        zipped[i] = [ar1[i], ar2.slice(i, ar2.length)];
      }
      return zipped;
    };
    return Ctrl;
  })();
  module.exports = Ctrl;
}).call(this);
