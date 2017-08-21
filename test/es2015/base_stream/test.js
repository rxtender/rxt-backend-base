import {
  Router, Counter, CounterItem,
  createCounterSubscription
} from './rxt/base_stream.rxt.js';

var assert = require('assert');

describe('creation of', function() {
  describe('Router object', function() {
    it('should succeed', function() {
      let router = new Router({});
      assert.notEqual(router, null);
    });
  });
});

describe('creation of', function() {
  describe('Counter observer', function() {
    it('should succeed', function() {
      let next = [];
      let completed = [];
      let error = [];
      let buffer = "";
      let transport = { "write": function(data) {
        buffer += data;
      }};
      let router = new Router(transport);

      // request creation of a remote observable
      let subscription = createCounterSubscription(
        (i) => { next.push(i)},
        () => { completed.push(true)},
        (e) => { error.push(e)});
      router.addSubscription(subscription);
      assert.equal(
        buffer,
        '{"what":"create","streamType":"Counter","streamId":0}'
      );
      buffer = "";

      // ack creation
      router.onMessage('{"what": "createAck", "streamId": 0}');

    });
  });
});

describe('creation of', function() {
  describe('Counter observer', function() {
    it('should fail when nack is received', function() {
      let next = [];
      let completed = [];
      let error = [];
      let buffer = "";
      let transport = { "write": function(data) {
        buffer += data;
      }};
      let router = new Router(transport);

      // request creation of a remote observable
      let subscription = createCounterSubscription(
        (i) => { next.push(i)},
        () => { completed.push(true)},
        (e) => { error.push(e)});
      router.addSubscription(subscription);
      assert.equal(
        buffer,
        '{"what":"create","streamType":"Counter","streamId":0}'
      );
      buffer = "";

      // nack creation
      router.onMessage('{"what": "createNack", "streamId": 0}');
      assert.equal(error.length, 1);
    });
  });
});

/*
describe('creation of', function() {
  describe('Counter observer', function() {
    it('should succeed', function() {
      let buffer = "";
      let transport = { "write": function(data) {
        buffer += data;
      }};
      let router = new Router(transport);
      router.createCounter();
      assert.Equal(buffer, "");
    });
  });
});
*/
