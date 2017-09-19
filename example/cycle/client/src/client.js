import {run} from '@cycle/rxjs-run';
import {Observable} from 'rxjs';
import {makeWebsocketDriver} from './websocket_driver.js';
import {makeRouterDriver} from './router_driver.js';
import {makeConsoleDriver} from './console_driver.js';

import {
  frame, unframe, router
} from './counter_rxt.js';

let dispose;

function main(sources) {
  const connection = sources.LINK.connect('localhost', 9999);
  const returnChannel$ = sources.ROUTER.linkout()
    .map(i => i.data);

  const linkRcv$ = connection.data
    .map( i => {
      return {
        "what": "data",
        "link": "foo",
        "data": i
      };
    });

  const console$ = connection.state
    .mergeMap( i => {
      return sources.ROUTER.Counter(1,10,1);
    })
    .map( i => i.value);

  return {
   ROUTER: linkRcv$,
   LINK: returnChannel$,
   CONSOLE: console$
  };
}

dispose = run(main, {
  CONSOLE:  makeConsoleDriver(),
  ROUTER:   router,
  LINK:     makeWebsocketDriver(),
});
