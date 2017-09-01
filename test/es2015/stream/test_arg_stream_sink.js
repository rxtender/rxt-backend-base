import {
  Router, Counter, CounterItem,
  createCounterSubscription
} from './arg_stream_rxt.js';

var assert = require('assert');

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
        [0,10,1],
        (i) => { next.push(i)},
        () => { completed.push(true)},
        (e) => { error.push(e)});
      router.addSubscription(subscription);
      assert.equal(
        buffer,
        '{"what":"create","streamType":"Counter","streamId":'
        + subscription.streamId + ',"args":[0,10,1]}'
      );
      buffer = "";

      // ack creation
      router.onMessage('{"what": "createAck", "streamId": '
      + subscription.streamId +'}');

    });
  });
});
