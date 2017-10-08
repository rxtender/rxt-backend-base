
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

var sinkStreamId = 0;
var sourceStreamId = 0;

function sinkStream(observer) {
  return {
    "streamId": sinkStreamId++, // @todo: integer overflow
    "observer": observer
  };
}

function sourceStream(stream) {
  return {
    "streamId": sourceStreamId++, // @todo: integer overflow
    "stream": stream
  };
}

function sinkEngine() {
  return {
    "link": [],
    "message": null
  };
}

function linkMessage(linkId, message) {
  return {
    "linkId": linkId,
    "message": message
  };
}

function processLinkItem(state, item, linkObserver) {
  switch(item.what) {
    case 'addLink':
      state.link[item.linkId] = [];
      if(linkObserver != null)
        linkObserver.next(addLinkMessage(item.linkId));
      break;

    case 'delLink':
      // todo: raise error on all streams
      state.link.splice(item.linkId, 1);
      if(linkObserver != null)
        linkObserver.next(delLinkMessage(item.linkId));
      break;
  }
  return state;
}

function processSinkItem(state, item, linkOutMessageObserver) {
  switch(item.what) {
    case 'createSink':
      const stream = sinkStream(item.observer);
      state.link[item.linkId][stream.streamId] = stream;
      linkOutMessageObserver.next(
        linkMessage(item.linkId, createMessage(
          item.streamType, stream.streamId, item.args))
      );
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
        linkOutMessageObserver.next(
          linkMessage(item.linkId, deleteMessage(index))
        );
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
  }
  return state;
}

function processSourceItem(state, item, factory, linkOutMessageObserver) {
  switch(item.what) {
    case 'create':
      {%- for stream in streams %}
      {% if not loop.first %}else {% endif%}if(item.streamType == '{{stream.identifier}}') {
        if(factory["{{stream.identifier}}"] == undefined) {
          console.log("no factory for stream {{stream.identifier}}");
        }

        const stream = factory["{{stream.identifier}}"]({%- for arg in stream.arg %}item.args[{{loop.index0}}]{% if not loop.last %}, {% endif%}{%- endfor %});
        const linkStream = sourceStream(stream);
        state.link[item.linkId][item.streamId] = linkStream;
        linkOutMessageObserver.next(linkMessage(item.linkId, ackMessage(item.streamId)));
        stream.subscribe(
          i => {
            linkOutMessageObserver.next();
          },
          e => {
            linkOutMessageObserver.error();
          },
          () => {
            linkOutMessageObserver.complete();
          }
        );
      }
      {%- endfor %}
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

export function router(sink$, factory = {}) {
  let sinkRequestObserver = null;
  let linkOutMessageObserver = null;
  let linkObserver = null;

  const sinkRequest$ = Observable.create( o => {
    sinkRequestObserver = o;
  });

  const linkOutMessage$ = Observable.create( o => {
    linkOutMessageObserver = o;
  });

  const link$ = Observable.create( o => {
    linkObserver = o;
  });

  const sinkControl = remuxLinkStreams(sink$)
    .share()
    .partition( i => i.what == "data");
  const sinkinData$ = sinkControl[0]
    .scan( (acc, i) => {
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
      acc = processSinkItem(acc, i, linkOutMessageObserver);
      acc = processSourceItem(acc, i, factory, linkOutMessageObserver);
      acc = processLinkItem(acc, i, linkObserver);
      return acc;
    }, sinkEngine())
    .subscribe();

  const linkOut$ = linkOutMessage$
    .map( i => {
      return {
        "what": "data",
        "linkId": i.linkId,
        "data": frame(i.message.toJson())
      };
    });

  return {
    "link": () => link$,
    "linkData": () => linkOut$

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
        console.log("counter 2");

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
