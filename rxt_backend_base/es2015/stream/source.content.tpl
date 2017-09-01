
{% for stream in streams %}

var id = 0;

function create{{stream.identifier}}Subscription(args, nextCbk, completedCbk, errorCbk) {
  return {
    'stream': "{{stream.identifier}}",
    'streamId': id++, // @bug: integer overflow
    'args': args,
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
  }

  delete() {
    for(subscription in this.subscriptions)
      delSubscription(this.subscriptions[subscription]);
  }

  addSubscription(subscription) {
    this.subscriptions[subscription.streamId] = subscription;
    this.transport.write(
      createMessage(subscription.stream, subscription.streamId, subscription.args)
      .toJson());
  }

  delSubscription(subscription) {
    if(typeof this.subscriptions[subscription.streamId] === 'undefined')
      return;

    this.transport.write(
      deleteMessage(subscription.streamId)
      .toJson());
    this.subscriptions.splice(subscription.streamId, 1);
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
        this.subscriptions.splice(subscription.streamId, 1);
        break;
      default:
        throw 'Invalid message type';
    }

  return
  }
}
