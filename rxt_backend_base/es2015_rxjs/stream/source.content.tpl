
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

var streamId = 0;

function sinkStream(observer) {
  return {
    "streamId": streamId++, // @bug: integer overflow
    "observer": observer
  };
}

function sinkEngine() {
  return {
    "link": [],
    "message": null
  };
}

function processSinkItem(state, item) {
  state.message = null;
  switch(item.what) {
    case 'createSink':
      const stream = sinkStream(item.observer);
      state.link[item.linkId][stream.streamId] = stream;
      state.message = createMessage(item.streamType, stream.streamId, item.args);
      state.message.linkId = item.linkId;
    break;

    case 'deleteSink':
      let index = -1;
      for(let id in state.link[item.linkId]) {
        if(state.link[item.linkId][id].observer == item.observer) {
          index = id;
          break;
        }
      }

      if(index != -1) {
        state.link[item.linkId].splice(index, 1);
        state.message = deleteMessage(index);
        state.message.linkId = item.linkId;
      }
    break;

    case 'createNack':
      state.link[item.linkId][item.streamId]
        .observer.error(null);
      state.link[item.linkId].splice(item.streamId, 1);
      break;

    case 'next':
      state.link[item.linkId][item.streamId]
        .observer.next(item.item);
      break;

    case 'completed':
      state.link[item.linkId][item.streamId]
        .observer.complete();
      break;

    case 'error':
      state.link[item.linkId][item.streamId]
        .observer.error(item.error);
      break;

    case 'addLink':
      state.link[item.linkId] = [];
      state.message = addLinkMessage(item.linkId);
      break;

    case 'delLink':
      // todo: raise error on all streams
      state.link.splice(item.linkId, 1);
      state.message = delLinkMessage(item.linkId);
      break;
  }
  return state;
}

function remuxLinkStreams(link$) {
  return link$.map( i => {
    return Observable.from([{
      "what": "addLink",
      "linkId": i.linkId
    }])
    .concat(
      i.stream.map( data => {
        return {
          "what": "data",
          "linkId" : i.linkId,
          "data": data
        };
      }),
      Observable.from([{
        "what": "delLink",
        "linkId": i.linkId
      }])
    );
  })
  .mergeAll()
  //.do( i => console.log(JSON.stringify(i)))
  ;
}

export function router(sink$) {
  let sinkRequestObserver = null;

  const sinkRequest$ = Observable.create( o => {
    sinkRequestObserver = o;

    // todo cleanup function
  });

  const sinkControl = remuxLinkStreams(sink$)
    .share()
    .partition( i => i.what == "data");
  const sinkinData$ = sinkControl[0].scan( (acc, i) => {
     const state = unframe(acc.context, i.data)
     return {
       "context": state.context,
       "packets": state.packets,
       "linkId": i.linkId
     };
   }, {'context':''})
   .mergeMap( (i) => {
     return Observable.from(i.packets)
      .map( packet => {
        return {
          "packet": packet,
          "linkId": i.linkId
        };
      });
   })
  .map( i => {
    let msg = msgFromJson(i.packet);
    msg.linkId = i.linkId;
    return msg;
  });
  const sinkinCommand$ = sinkControl[1];

  const engine$ = Observable.merge(sinkinCommand$, sinkinData$, sinkRequest$)
    .scan( (acc, i) => {
      return processSinkItem(acc, i);
    }, sinkEngine())
    .map( i => i.message)
    .filter(i => i != null);

  const engine = engine$.share()
    .partition( i => (i.what === "addLink") || (i.what === "delLink"));

  const link$ = engine[0];
  const linkOut$ = engine[1]
    .map( i => {
      return {
        "what": "data",
        "linkId": i.linkId,
        "data": frame(i.toJson())
      };
    })

  return {
    "link": () => link$,
    "linkData": () => {
      return linkOut$;
    }

    {%- for stream in streams %}
    {%- if loop.first %}, {% endif%}

    "{{stream.identifier}}": (linkId, {%- for arg in stream.arg %}{{arg.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %}) => {
      const stream = Observable.create( o => {
        sinkRequestObserver.next(
          createSinkMessage(
            linkId,
            "{{stream.identifier}}",
            o,
            [{%- for arg in stream.arg %}{{arg.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %}]
          )
        );

        return () => {
          sinkRequestObserver.next(
            deleteSinkMessage(linkId, o));
          };
        }
      );
      return stream;
    }

    {%- if not loop.last %}, {% endif%}
    {%- endfor %}
  };
}
