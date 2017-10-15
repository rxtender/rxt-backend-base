import {Observable, Subject} from 'rxjs';
import {
  router,
} from './counter_rxt.js';
import {Socket} from 'net';

let connection = [];

function createConnection(id, host, port) {
  const state$ = Observable.create(stateObserver => {
    let dataObserver = null;
    const data$ = Observable.create(observer => {
      dataObserver = observer;
    });

    connection[id] = new Socket();
    connection[id].setEncoding('utf8');
    connection[id].connect(port, host, function() {
        console.log('CONNECTED TO: ' + host + ':' + port);
        stateObserver.next({
          "linkId": id,
          "stream": data$
        })
    });

    connection[id].on('data', function(data) {
      dataObserver.next(data);
    });

    connection[id].on('close', function() {
        dataObserver.complete();
        stateObserver.complete();
        connection.splice(id, 1);
    });
  });

  return state$;
}

function tcpClient(sink$) {
  sink$.subscribe( (i) => {
    connection[i.linkId].write(i.data);
  });

  return {
    "connect" : createConnection
  };
}

function consoleDriver(sink$) {
  sink$.subscribe( (i) => {
    console.log('console: ' + i);
  });
}

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

const consoleProxy$ = new Subject();
const routerProxy$ = new Subject();
const linkProxy$ = new Subject();

const sources = {
  CONSOLE: consoleDriver(consoleProxy$),
  ROUTER: router(routerProxy$),
  LINK: tcpClient(linkProxy$)
};

const sinks = main(sources);

sinks.ROUTER.subscribe(routerProxy$);
sinks.LINK.subscribe(linkProxy$);
sinks.CONSOLE.subscribe(consoleProxy$);
