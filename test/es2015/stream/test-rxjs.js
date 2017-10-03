
import {
  router, frame, unframe,
  nackMessage, nextMessage,
  CounterItem
} from './arg_stream_rxt.js';

import { Subject } from 'rxjs';

var assert = require('assert');

describe('creation of', function() {
  describe('router', function() {
    it('should succeed', function() {
      const sink$ = new Subject();

      let testRouter = router(sink$);
      assert.notEqual(testRouter, null);
    });
  });
});

describe('adding a', function() {
  describe('link', function() {
    it('should emit an addLink item on link stream', function() {
      let linkItems = [];

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
      testRouter.link()
        .subscribe(
          (i) => {
            linkItems.push(i);
          }
        );

      sink$.next({
        "linkId": "test",
        "stream": linkSource$
      });

      assert.equal(linkItems.length, 1);
      assert.equal(linkItems[0].what, "addLink");
      assert.equal(linkItems[0].linkId, "test");
    });
  });
});

describe('removing a', function() {
  describe('link', function() {
    it('should emit a delLink item on link stream', function() {
      let linkItems = [];

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
      testRouter.link()
        .subscribe(
          (i) => {
            linkItems.push(i);
          }
        );

      sink$.next({
        "linkId": "test",
        "stream": linkSource$
      });

      linkItems = [];
      linkSource$.complete();

      assert.equal(linkItems.length, 1);
      assert.equal(linkItems[0].what, "delLink");
      assert.equal(linkItems[0].linkId, "test");
    });
  });
});

describe('creation of', function() {
  describe('Counter stream', function() {
    it('should succeed', function() {
      let linkItems = [];

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
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

      const counter$ = testRouter.Counter('test', 10, 100, 2);
      assert.notEqual(counter$, null);

      counter$.subscribe();
      assert.equal(linkItems.length, 1);
      assert.equal(linkItems[0].what, "data");
      assert.equal(linkItems[0].linkId, "test");

      const item = JSON.parse(linkItems[0].data);
      assert.equal(item.what, "create");
      assert.equal(item.streamType, "Counter");
      assert.deepEqual(item.args, [10, 100, 2]);
    });
  });
});

describe('Counter stream', function() {
    it('should raise error on creation nack', function() {
      let error = 3;
      let streamId = 0;

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
      testRouter.linkData()
        .subscribe(
          i => {
            const message = JSON.parse(unframe('', i.data).packets[0]);
            if(message.what == 'create')
              streamId = message.streamId;
          }
        );

      sink$.next({
        "linkId": "test",
        "stream": linkSource$
      });

      const counter$ = testRouter.Counter('test', 10, 100, 2);
      counter$.subscribe(
        i => { },
        e => { error = e; }
      );

      linkSource$.next(frame(nackMessage(streamId).toJson()));
      assert.equal(error, null);
    });
});

describe('processing of', function() {
  describe('next messages', function() {
    it('should call the next callback', function() {
      let value = -1;
      let streamId = 0;

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
      testRouter.linkData()
        .subscribe(
          i => {
            const message = JSON.parse(unframe('', i.data).packets[0]);
            if(message.what == 'create')
              streamId = message.streamId;
          }
        );

      sink$.next({"linkId": "test", "stream": linkSource$});

      const counter$ = testRouter.Counter('test', 10, 100, 2);
      counter$.subscribe( i => { value = i.value; });

      linkSource$.next(frame(JSON.stringify({
        "what": "next", "streamId": streamId,
        "item": {"value": 0}}))
      );
      assert.equal(value, 0);

      linkSource$.next(frame(JSON.stringify({
        "what": "next", "streamId": streamId,
        "item": {"value": 1}}))
      );
      assert.equal(value, 1);
    });
  });
});

describe('processing of', function() {
  describe('completed message', function() {
    it('should call the complete callback', function() {
      let complete = false;
      let streamId = 0;

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
      testRouter.linkData()
        .subscribe(
          i => {
            const message = JSON.parse(unframe('', i.data).packets[0]);
            if(message.what == 'create')
              streamId = message.streamId;
          }
        );

      sink$.next({"linkId": "test", "stream": linkSource$});

      const counter$ = testRouter.Counter('test', 10, 100, 2);
      counter$.subscribe(
        i => {},
        e => {},
        () => { complete = true;}
      );

      linkSource$.next(frame(JSON.stringify({
        "what": "completed", "streamId": streamId}))
      );
      assert.equal(complete, true);
    });
  });
});

describe('processing of', function() {
  describe('error message', function() {
    it('should call the error callback', function() {
      let error = null;
      let streamId = 0;

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
      testRouter.linkData()
        .subscribe(
          i => {
            const message = JSON.parse(unframe('', i.data).packets[0]);
            if(message.what == 'create')
              streamId = message.streamId;
          }
        );

      sink$.next({"linkId": "test", "stream": linkSource$});

      const counter$ = testRouter.Counter('test', 10, 100, 2);
      counter$.subscribe(
        i => {},
        e => { error = e}
      );

      linkSource$.next(frame(JSON.stringify({
        "what": "error", "streamId": streamId,
        "message": "invalid foo" }))
      );
      assert.equal(error, "invalid foo");
    });
  });
});

describe('disposal of', function() {
  describe('a stream', function() {
    it('should send a delete message', function() {
      let disposed = false;
      let streamId = 0;

      const sink$ = new Subject();
      const linkSource$ = new Subject();

      let testRouter = router(sink$);
      testRouter.linkData()
        .subscribe(
          i => {
            const message = JSON.parse(unframe('', i.data).packets[0]);
            if(message.what == 'create')
              streamId = message.streamId;
            else if(message.what == 'delete')
              disposed = true;
          }
        );

      sink$.next({"linkId": "test", "stream": linkSource$});

      const counter$ = testRouter.Counter('test', 10, 100, 2);
      const subscription = counter$.subscribe();
      subscription.unsubscribe();

      assert.equal(disposed, true);
    });
  });
});
