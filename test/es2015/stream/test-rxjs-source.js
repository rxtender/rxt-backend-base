import {
  router, frame, unframe,
  nackMessage, nextMessage, createMessage,
  CounterItem, CounterItemMessage
} from './arg_stream_rxt.js';

import { Subject, Observable } from 'rxjs';
var assert = require('assert');

describe('processing of', function() {
  describe('create message', function() {
    it('should create a stream and ack it', function() {
      let linkItems = [];
      let factory = [];

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$, {
        "Counter": (start,end,step) => {
          factory.push([start, end, step]);
          return Observable.create();
        }
      });
      testRouter.linkData()
        .subscribe(
          (i) => {
            linkItems.push(i);
          }
        );

      sink$.next({
        "linkId": "test",
        "stream": linkSource$
      });
      const streamId = 42;
      linkSource$.next(frame(createMessage("Counter", streamId, [10, 100, 1]).toJson()));

      assert.equal(factory.length, 1);
      assert.deepEqual(factory[0], [10, 100, 1]);

      assert.equal(linkItems.length, 1);
      assert.equal(linkItems[0].what, "data");
      assert.equal(linkItems[0].linkId, "test");
      const createItem = JSON.parse(unframe('', linkItems[0].data).packets[0]);
      assert.equal(createItem.what, "createAck");
      assert.equal(createItem.streamId, streamId);
    });
  });
});

describe('publication of', function() {
  describe('an item', function() {
    it('should send an item message', function() {
      let linkItems = [];
      let complete = false;

      const sink$ = new Subject();
      const linkSource$ = new Subject();
      let testRouter = router(sink$, {
        "Counter": (start,end,step) => {
          return Observable.from([10, 11])
            .map( i => CounterItem(i));
        }
      });
      testRouter.linkData()
        .subscribe(
          i => { linkItems.push(i); },
          e => {},
          () => { complete = true; }
        );

      sink$.next({
        "linkId": "test",
        "stream": linkSource$
      });
      const streamId = 42;
      linkSource$.next(frame(createMessage("Counter", streamId, [10, 100, 1]).toJson()));

      assert.equal(linkItems.length, 3);
      let item = JSON.parse(unframe('', linkItems[1].data).packets[0]);
      assert.equal(item.what, "next");
      assert.equal(item.streamId, streamId);
      assert.equal(item.item.value, 10);

      item = JSON.parse(unframe('', linkItems[2].data).packets[0]);
      assert.equal(item.what, "next");
      assert.equal(item.streamId, streamId);
      assert.equal(item.item.value, 11);

      assert.equal(complete, true);
    });
  });
});
