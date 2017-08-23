
{% for stream in streams %}

function create{{stream.identifier}}Subscription(nextCbk, completedCbk, errorCbk) {
  return {
    'stream': "{{stream.identifier}}",
    'args': [],
    'observer': {
      'next': (i) => { nextCbk(i); },
      'completed': () => { completedCbk(); },
      'error': (e) => {errorCbk(e); }
    }
  };
}
{% endfor %}

class Router {
  constructor(transport) {
    this.transport = transport;
    this.subscriptions = [];
    this.id = 0;
  }

  delete() {
    for(subscription in this.subscriptions)
      this.subscriptions[subscription].delete()
    this.subscriptions = []
  }

  addSubscription(subscription) {
      const id = this.id++;
      this.subscriptions[id] = subscription;
      this.transport.write(
        createMessage(subscription.stream, id)
        .toJson());
  }

  delSubscription(subscription) {
    const rxtObserver = this.subscriptions.find((e) => { e === subscription });
    if(rxtObserver != undefined) {
      this.subscriptions[rxtObserver.id].delete()
    }
  }

  onMessage(msg) {
    const message = msgFromJson(msg);
    switch(message.what) {
      case 'next':
        this.subscriptions[message.streamId]
        .observer.next(message.item);
        break;
      case 'completed':
        this.subscriptions[message.streamId]
        .observer.completed();
        break;
      case 'error':
        this.subscriptions[message.streamId]
        .observer.error(message.message);
        break;
      case 'createAck':
        break;
      case 'createNack':
        const streamId = message.streamId;
        const subscription = this.subscriptions[streamId];
        subscription.observer.error(Error(message.reason));
        this.delSubscription(subscription);
        break;
      default:
        throw 'Invalid message type';
    }

  return
  }
}
