import {
  SingleField, SingleField_deserialize, SingleField_serialize,
  MultiFields
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
      let item = MultiFields(1 ,2 ,3 ,4 ,true ,1.2, "baz");
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

describe('deserialization of', function() {
  describe('SingleField object', function() {
    it('should return the object encoded in the json string', function() {
      const expectedItem = {
        "foo32": 42
      };
      const itemJson = '{"foo32": 42}';
      let item = SingleField_deserialize(itemJson);
      assert.deepEqual(item, expectedItem);
    });
  });
});

describe('deserialization of', function() {
  describe('SingleField object', function() {
    it('should fail when json string is missing fields', function() {
      const itemJson = '{}';
      let item = SingleField_deserialize(itemJson);
      assert.deepEqual(item, null);
    });
  });
});

describe('deserialization of', function() {
  describe('SingleField object', function() {
    it('should fail when json string is invalid', function() {
      const itemJson = '{ blah }';
      let item = SingleField_deserialize(itemJson);
      assert.deepEqual(item, null);
    });
  });
});

describe('serialization of', function() {
  describe('SingleField object', function() {
    it('should return the json encoded string of object', function() {
      const item = {
        "foo32": 42
      };
      const expectedJson = '{"foo32":42}';
      let itemJson = SingleField_serialize(item);
      assert.deepEqual(itemJson, expectedJson);
    });
  });
});

describe('serialization of', function() {
  describe('SingleField object', function() {
    it('should fail when object is missing fields', function() {
      const item = {};
      let itemJson = SingleField_serialize(item);
      assert.deepEqual(itemJson, null);
    });
  });
});

describe('serialization of', function() {
  describe('SingleField object', function() {
    it('should return json string with only foo32 when object contains additional attributes', function() {
      const expectedJson = '{"foo32":42}';
      const item = SingleField(42);
      item.bar = "some";
      let itemJson = SingleField_serialize(item);
      assert.deepEqual(itemJson, expectedJson);
    });
  });
});
