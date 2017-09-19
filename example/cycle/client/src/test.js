'use strict';

var cycle = require('@cycle/rxjs-run');

var rx = require('rxjs');

function main(sources) {
  console.log('main');
  const test$ = rx.Observable.from([1,2,3,4,5]);
  //test$.subscribe( msg => { console.log(msg); } );

  return {
   log: test$
  };
}

cycle.run(main, {
  log:   (msg$) => {
    console.log('log');
    msg$.subscribe( msg => { console.log(msg); } );
  },
});
