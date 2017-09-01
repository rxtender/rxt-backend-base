import {
  Router, Counter, CounterItem,
  createCounterSubscription
} from './base_stream_rxt.js';

var assert = require('assert');

function createRouter(streamType) {
  let next = [];
  let completed = [];
  let error = [];
  let buffer = "";
  let transport = { "write": function(data) {
    transport.buffer = data;
  }};
  let router = new Router(transport);

  // request creation of a remote observable
  let subscription = createCounterSubscription(
    [],
    (i) => { next.push(i)},
    () => { completed.push(true)},
    (e) => { error.push(e)});
  router.addSubscription(subscription);

  // ack creation
  router.onMessage(
    '{"what": "createAck", "streamId":' + subscription.streamId + '}');

  return {
    'router': router,
    'next': next,
    'completed': completed,
    'error': error,
    'subscription': subscription,
    'transport': transport
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
        [],
        (i) => { next.push(i)},
        () => { completed.push(true)},
        (e) => { error.push(e)});
      router.addSubscription(subscription);
      assert.equal(
        buffer,
        '{"what":"create","streamType":"Counter","streamId":'
        + subscription.streamId + ',"args":[]}'
      );
      buffer = "";

      // ack creation
      router.onMessage('{"what": "createAck", "streamId": '
      + subscription.streamId +'}');

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
        [],
        (i) => { next.push(i)},
        () => { completed.push(true)},
        (e) => { error.push(e)});
      router.addSubscription(subscription);
      assert.equal(
        buffer,
        '{"what":"create","streamType":"Counter","streamId":'
        + subscription.streamId +',"args":[]}'
      );
      buffer = "";

      // nack creation
      router.onMessage('{"what": "createNack", "streamId":'
      + subscription.streamId +'}');
      assert.equal(error.length, 1);
    });
  });
});

describe('processing of', function() {
  describe('next messages', function() {
    it('should call the next callback', function() {
      context = createRouter("Counter");
      context.router.onMessage(
        '{"what": "next", "streamId":'
        + context.subscription.streamId + ', "item": {"value": 42}}'
      );
      context.router.onMessage(
        '{"what": "next", "streamId":'
        + context.subscription.streamId + ', "item": {"value": 142}}'
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
        '{"what": "completed", "streamId":'
        + context.subscription.streamId + '}'
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
        '{"what": "error", "streamId":'
        + context.subscription.streamId + ',"message":"invalid foo"}'
      );
      assert.equal(context.error.length, 1);
      assert.equal(context.error[0], "invalid foo");
    });
  });
});

describe('deletion of', function() {
  describe('a subscription', function() {
    it('should work', function() {
      context = createRouter("Counter");
      context.router.delSubscription(context.subscription);
      assert.equal(
        context.transport.buffer,
        '{"what":"delete","streamId":'
        + context.subscription.streamId +'}'
      );
    });
  });
});
