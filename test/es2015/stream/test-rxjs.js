
import {
  Router, createCounterObservable
} from './arg_stream_rxt.js';

describe('creation of', function() {
  describe('Counter observer', function() {
    it('should succeed', function() {
      let next = [];
      let completed = [];
      let error = [];
      let buffer = "";
      let transport = { "write": function(data) {
        buffer += data;
      }};
      let router = new Router(transport);

      createCounterObservable(router, 10, 100, 2)
      .subscribe(
        (i) => { next.push(i)},
        () => { completed.push(true)},
        (e) => { error.push(e)}
      );


    });
  });
});
