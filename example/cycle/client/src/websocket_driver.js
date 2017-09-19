import {Observable} from 'rxjs';
import {Socket} from 'net';

//var net = require('net');

function makeWebsocketDriver() {
  let connection = null;

  function createConnection(host, port) {
    let stateObserver = null;

    const state$ = Observable.create(observer => {
      console.log('createConnection state$ subscribed');
      stateObserver = observer;
    });

    const data$ = Observable.create(observer => {
      console.log('createConnection data$ subscribed');
      connection = new Socket();
      connection.setEncoding('utf8');
      connection.connect(port, host, function() {
          console.log('CONNECTED TO: ' + host + ':' + port);
          stateObserver.next(true);
      });

      connection.on('data', function(data) {
        observer.next(data);
      });

      connection.on('close', function() {
          observer.complete();
          stateObserver.complete();
      });
    });


    return {
      data: data$,
      state: state$
    };
  }

  return function WebsocketDriver(sink$) {
    console.log("created WebsocketDriver: " + sink$);
    sink$.subscribe( (i) => {
      console.log('WebsocketDriver next: ' + i);
      connection.write(i);
    });

    return {
      "connect" : createConnection
    };
  }
}

export { makeWebsocketDriver };
