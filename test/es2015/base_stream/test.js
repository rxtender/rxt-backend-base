import {
  Router, Counter, CounterItem
} from './rxt/base_stream.rxt.js';

var assert = require('assert');

describe('creation of', function() {
  describe('Router object', function() {
    it('should should succeed', function() {
      let router = new Router({});
      assert.notEqual(router, null);
    });
  });
});
