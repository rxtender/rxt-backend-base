import {Observable} from 'rxjs';
import {Socket} from 'net';

//var net = require('net');

function makeWebsocketDriver() {
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

  return function WebsocketDriver(sink$) {
    sink$.subscribe( (i) => {
      connection[i.linkId].write(i.data);
    });

    return {
      "connect" : createConnection
    };
  }
}

export { makeWebsocketDriver };
