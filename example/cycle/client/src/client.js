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
  const linkRcv$ = sources.LINK.connect('counter', 'localhost', 9999);

  const returnChannel$ = sources.ROUTER.linkData();

  const console$ = sources.ROUTER.link()
    .map( i => {
      return sources.ROUTER.Counter(i.linkId, 1,10,1)
    })
    .mergeAll()
    .map( i => i.value);;

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
