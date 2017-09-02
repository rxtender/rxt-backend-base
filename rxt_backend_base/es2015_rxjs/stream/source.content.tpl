
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
