import {
  Router, Counter, CounterItem,
  createCounterSubscription
} from './rxt/base_stream.rxt.js';

var assert = require('assert');

function createRouter(streamType) {
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
  buffer = "";

  // ack creation
  router.onMessage('{"what": "createAck", "streamId":0}');

  return {
    'router': router,
    'buffer': buffer,
    'next': next,
    'completed': completed,
    'error': error
  }
}

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

describe('processing of', function() {
  describe('next messages', function() {
    it('should call the next callback', function() {
      context = createRouter("Counter");
      context.router.onMessage(
        '{"what": "next", "streamId":"0", "item": {"value": 42}}'
      );
      context.router.onMessage(
        '{"what": "next", "streamId":"0", "item": {"value": 142}}'
      );
      assert.equal(context.next.length, 2);
      assert.deepEqual(context.next[0], { value: 42 });
      assert.deepEqual(context.next[1], { value: 142 });
    });
  });
});

describe('processing of', function() {
  describe('completed message', function() {
    it('should call the completed callback', function() {
      context = createRouter("Counter");
      context.router.onMessage(
        '{"what": "completed", "streamId":"0"}'
      );
      assert.equal(context.completed.length, 1);
      assert.equal(context.completed[0], true);
    });
  });
});

describe('processing of', function() {
  describe('error message', function() {
    it('should call the error callback', function() {
      context = createRouter("Counter");
      context.router.onMessage(
        '{"what": "error", "streamId":"0","message":"invalid foo"}'
      );
      assert.equal(context.error.length, 1);
      assert.equal(context.error[0], "invalid foo");
    });
  });
});
