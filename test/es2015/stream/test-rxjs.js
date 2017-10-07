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
