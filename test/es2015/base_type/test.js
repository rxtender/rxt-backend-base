import {Simple1} from './lib/base_type.js';
var assert = require('assert');

describe('creation of', function() {
  describe('Simple1 object', function() {
    it('should return an object with the provided parameters', function() {
      let expectedItem = {
        "foo32": 1,
        "bar32": 2,
        "foo64": 3,
        "bar64": 4,
        "biz": true,
        "buz": 1.2
      };
      let item = Simple1(1 ,2 ,3 ,4 ,true ,1.2);
      assert.deepEqual(item, expectedItem);
    });
  });
});
