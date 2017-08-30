
{% for stream in streams %}
  function create{{stream.identifier}}Observable(router) {
    const observable = Observable.create(observer => {
      const subscription = create{{stream.identifier}}Subscription(
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
