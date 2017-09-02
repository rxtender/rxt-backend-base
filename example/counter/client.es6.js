import {
  frame, unframe, Router,
  createCounterObservable
} from './counter_rxt.js';

var net = require('net');

var HOST = '127.0.0.1';
var PORT = 9999;

var client = new net.Socket();

var router = null;
var context = '';
client.connect(PORT, HOST, function() {
    console.log('CONNECTED TO: ' + HOST + ':' + PORT);
    router = new Router({"write": (d) => {
      client.write(frame(d));
    }});

    console.log('creating observable');
    createCounterObservable(router, 1, 10, 1)
    .subscribe(
      (i) => { console.log('tick: ' + i.value); },
      (e) => { console.log('stream error'); },
      () => {
        console.log('completed');
        process.exit();
      }
    );
});

client.on('data', function(data) {
    const result = unframe(context, data.toString());
    context = result.context;
    result.packets.forEach( (e) => {
      router.onMessage(e);
    })

});

client.on('close', function() {
    console.log('Connection closed');
});
