
class Router {
  constructor(transport) {
    this.transport = transport;
    this.observables = [];
    this.id = 0;
  }

  delete() {
    for(observable in this.observables)
      this.observables[observable].delete()
    this.observables = []
  }

  addObservable(observable) {
      const id = self.id++;
      this.observables[id] = observable;
  }

  onMessage(msg) {
    const message = msg_from_json(msg);
    if(message.what == 'createAck') {
      //const stream_id = message.stream_id;
    }
    else if(message.what == 'createNack') {
      const stream_id = message.stream_id;
      const observable = this.observables[stream_id];
      observable.error(Error(message.reason));
    }
    else {
      throw 'Invalid message type';
    }

  return
  }

{% for stream in streams %}
  create{{stream.identifier}}() {
    const observable = Observable.create(observer => {
      this.transport.write(
        create_message('{{stream.identifier}}')
        .toJson());
    });

    this.add_observable(observable);
    return observable;
  }
{% endfor %}

}
