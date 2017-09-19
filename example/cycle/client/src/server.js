import {run} from '@cycle/rxjs-run';
import {Observable} from 'rxjs';
import {makeTcpServerDriver} from './tcpserver_driver.js';
import {makeConsoleDriver} from './console_driver.js';
import {makeRouterDriver} from './router_driver.js';

import {
  frame, unframe, router
} from './counter_rxt.js';

let dispose;

function server2router(item) {
  switch(item.what) {
    case "accept":
      return {
        "what": "addLink",
        "link": item.socket
      };
    break;

    case "close":
      return {
        "what": "delLink",
        "link": item.socket
      };
    break;

    case "data":
      return {
        "what": "data",
        "link": item.socket,
        "data": item.data
      };
    break;
  }
}

function router2server(item) {
  switch(item.what) {
    case "data":
      return {
        "what": "data",
        "socket": item.link,
        "data": item.data
      };
    break;
  }
}

function main(sources) {
  const linkIn$ = sources.LINK.listen('localhost', 9999)
    .map(server2router);
  const returnChannel$ = sources.ROUTER.linkout()
    .map(router2server);

  return {
    ROUTER: linkIn$,
    CONSOLE: linkIn$,
    LINK: returnChannel$
  };
}

dispose = run(main, {
  CONSOLE:  makeConsoleDriver(),
  ROUTER:   router,
  LINK:     makeTcpServerDriver(),
});
