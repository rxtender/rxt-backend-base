import {
  SingleField, MultiFields
} from './rxt/base_type.rxt.js';

var assert = require('assert');

describe('creation of', function() {
  describe('SingleField object', function() {
    it('should return an object with the provided parameters', function() {
      let expectedItem = {
        "foo32": 42
      };
      let item = SingleField(42);
      assert.deepEqual(item, expectedItem);
    });
  });
});

describe('creation of', function() {
  describe('SingleField object', function() {
    it('should fail when field count is not correct', function() {
      assert.throws( () => { return SingleField(); }, Error);
      assert.throws( () => { return SingleField(1, 2); }, Error);
    });
  });
});


describe('creation of', function() {
  describe('MultiFields object', function() {
    it('should return an object with the provided parameters', function() {
      let expectedItem = {
        "foo32": 1,
        "bar32": 2,
        "foo64": 3,
        "bar64": 4,
        "biz": true,
        "buz": 1.2,
        "name": "baz"
      };
      let item = MultiFields(1, 2, 3, 4, true, 1.2, "baz");
      assert.deepEqual(item, expectedItem);
    });
  });
});

describe('creation of', function() {
  describe('MultiFields object', function() {
    it('should fail when field count is not correct', function() {
      assert.throws( () => { return MultiFields(1, 2 ,3 ,4 ,true ,1.2); }, Error);
      assert.throws( () => { return MultiFields(1, 2 ,3 ,4 ,true ,1.2, "me", "you"); }, Error);
    });
  });
});
