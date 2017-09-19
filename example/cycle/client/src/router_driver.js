import {Observable} from 'rxjs';
import {
  frame, unframe, router,
  createCounterObservable, createCounterSubscription
} from './counter_rxt.js';

export function makeRouterDriver() {
  let router = new Router();

  function createReturnChannel() {
    console.log('created ReturnChannel:');
    return router.returnChannel()
      .map( i => frame(i) );
  }

  function createCounter(start, end, step) {
    console.log('created Counter:' + start);
    //return createCounterObservable(router, start, end, step);
    return Observable.create( (observer) => {
      console.log('subscribed to Counter');
      const subscription = createCounterSubscription(
        [start, end, step],
        (i) => { observer.next(i);},
        () => { observer.complete()},
        (e) => { observer.error(e)}
      );

      router.addSubscription(subscription);
      return () => { router.delSubscription(subscription)};
    });
  }

  return function RouterDriver(sink$) {
    console.log('created RouterDriver:' + sink$);

    sink$
     .scan( (acc, i) => {
        return unframe(acc.context, i);
      }, {'context':''})
      .mergeMap( (i) => {
        return Observable.from(i.packets);
      })
      .subscribe(
        (i) => {
          router.onMessage(i);
        },
        (e) => {
          console.log("RouterDriver error: " + e);
        },
        () => {
          console.log("RouterDriver complete:");
        }
    );

    return {
      count : createCounter,
      returnChannel : createReturnChannel
    };
  }
}
