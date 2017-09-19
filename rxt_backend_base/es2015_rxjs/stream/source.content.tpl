
{% for stream in streams %}
  function create{{stream.identifier}}Observable(router {%- for arg in stream.arg %}, {{arg.identifier}} {%- endfor %}) {
    const observable = Observable.create(observer => {
      const subscription = create{{stream.identifier}}Subscription(
        [{%- for arg in stream.arg %}{{arg.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %}],
        (i) => { observer.next(i)},
        () => { observer.complete()},
        (e) => { observer.error(e)}
      );

      router.addSubscription(subscription);
      return () => { router.delSubscription(subscription)};
    });

    return observable;
  }
{% endfor %}

var id = 0;

function sinkStream(observer) {
  return {
    "streamId": id++, // @bug: integer overflow
    "observer": observer
  };
}

function sinkEngine() {
  return {
    "sinkStreams": [],
    "packet": null
  };
}

function processSinkItem(state, item) {
  state.packet = null;
  switch(item.what) {
    case 'createSink':
      const stream = sinkStream(item.observer);
      state.sinkStreams[stream.streamId] = stream;
      state.packet = createMessage(item.streamType, stream.streamId, item.args);
    break;

    case 'deleteSink':
      const index = state.sinkStreams.indexOf(item.observer);
      if(index != -1) {
        state.sinkStreams.splice(index, 1);
        state.packet = deleteMessage(index);
      }
    break;

    case 'next':
      state.sinkStreams[item.streamId]
        .observer.next(item.item);
      break;

    case 'completed':
      state.sinkStreams[item.streamId]
        .observer.complete();
      break;

    case 'error':
      state.sinkStreams[item.streamId]
        .observer.error(item.error);
      break;
  }
  return state;
}

export function router(linkIn$) {
  let sinkStreams = [];
  let sinkRequestObserver = null;

  const sinkRequest$ = Observable.create( o => {
    sinkRequestObserver = o;

    // todo cleanup function
  });

  const sinkControl = linkIn$.partition( i => i.what == "data");
  const sinkinData$ = sinkControl[0].scan( (acc, i) => {
     return unframe(acc.context, i.data);
   }, {'context':''})
   .mergeMap( (i) => {
     return Observable.from(i.packets);
   })
  .map( i => {
    return msgFromJson(i);
  });
  const sinkinCommand$ = sinkControl[1];

  const sinkOut$ = Observable.merge(sinkinCommand$, sinkinData$, sinkRequest$)
    .scan( (acc, i) => {
      return processSinkItem(acc, i);
    }, sinkEngine())
    .map( i => i.packet)
    .filter(i => i != null);

  const linkOut$ = Observable.merge(sinkOut$)
    .map( i => i.toJson())
    .map( i => frame(i) )
    .map( i => {
      return {
        "what": "data",
        "data": i
      }
    });

  return {
    "linkout": () => {
      return linkOut$;
    }
    {%- for stream in streams %}
    {%- if loop.first %}, {% endif%}

    "{{stream.identifier}}": ({%- for arg in stream.arg %}{{arg.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %}) => {
      const stream = Observable.create( o => {
        sinkRequestObserver.next(
          createSinkMessage(
            "{{stream.identifier}}",
            o,
            [{%- for arg in stream.arg %}{{arg.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %}]
          )
        );

        return () => {
          sinkRequestObserver.next(
            deleteSinkMessage(o));
          };
        }
      );
      return stream;
    }

    {%- if not loop.last %}, {% endif%}
    {%- endfor %}
  };
}
