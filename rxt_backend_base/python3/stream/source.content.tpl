
class RouterError(Exception):
    pass


class SourceSubscription(object):
    def __init__(self, id, factory):
        if factory == None:
            raise RouterError('No factory')
        self.id = id
        self.factory = factory
        self.stream = None

    def set_subscription(self, subscription_id):
        self.subscription = subscription_id

class Router(object):
    id = 1
    # Factory functions index
    CREATE = 0
    DELETE = 1
    {%- for stream in streams %}
    {{stream.identifier}}_factory = None
    {%- endfor %}

    def __init__(self, transport):
        self.transport = transport
        self.streams = []
        return

    def __del__(self):
        for stream in self.streams:
            stream.factory[Router.DELETE](stream.stream)
        streams = None
        return

    {% for stream in streams %}
    def set_{{stream.identifier}}_factory(create, delete):
        Router.{{stream.identifier}}_factory = [create, delete]

    def create_stream_{{stream.identifier}}(self, stream_id):
        stream = SourceSubscription(stream_id, Router.{{stream.identifier}}_factory)
        stream.set_subscription(stream.factory[Router.CREATE](
            self.{{stream.identifier}}_next,
            self.{{stream.identifier}}_completed,
            self.{{stream.identifier}}_error,
            self.{{stream.identifier}}_unsubscribe
        ))
        self.streams.append(stream)

    def {{stream.identifier}}_next(subscription, item):
        return
    def {{stream.identifier}}_completed(subscription):
        return
    def {{stream.identifier}}_error(subscription, message):
        return
    def {{stream.identifier}}_unsubscribe(subscription):
        return

    {% endfor %}

    def on_create_message(self, message):
        {%- for stream in streams %}
        {% if not loop.first %}el{% endif%}if message.stream_type == '{{stream.identifier}}':
            self.create_stream_{{stream.identifier}}(message.stream_id)
        {%- endfor %}


    def on_delete_message(self, id):
        for stream in self.streams:
            if stream.id == id:
                stream.factory[Router.DELETE].delete(stream.stream)
                self.streams.remove(stream)
                break
        return None

    def ack_create(self, id):
        msg = CreateAckMessage(id)
        self.transport.write(msg.to_json())

    def on_message(self, msg):
        message = msg_from_json(msg)
        if message.what == 'create':
            self.on_create_message(message)
            self.ack_create(message.stream_id)
        elif message.what == 'delete':
            self.on_delete_message(message.stream_id)

        return
