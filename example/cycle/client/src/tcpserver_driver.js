import {Observable} from 'rxjs';
import {createServer} from 'net';

export function makeTcpServerDriver() {
  let connection = null;

  function listen(host, port) {
    const server$ = Observable.create(observer => {
      createServer(function(sock) {
        console.log('CONNECTED: ' + sock.remoteAddress +':'+ sock.remotePort);
        observer.next({"what": "accept", "socket": sock});

        sock.on('data', function(data) {
          console.log('DATA ' + sock.remoteAddress + ': ' + data);
          observer.next({"what": "data", "socket": sock, "data": data});
        });

        sock.on('close', function(data) {
          console.log('CLOSED: ' + sock.remoteAddress +' '+ sock.remotePort);
          observer.next({"what": "close", "socket": sock});
        });
      }).listen(port, host);
    });

    return server$;
  }

  return function TcpServerDriver(sink$) {
    console.log("created TcpServerDriver: " + sink$);
    sink$.subscribe( (i) => {
      console.log('TcpServerDriver next: ' + i);
      i.socket.write(i.data);
    });

    return {
      "listen" : listen
    };
  }
}
