
class RouterError(Exception):
    pass


class SourceStream(object):
    def __init__(self, id, delete):
        self.id = id
        self.delete = delete

class Router(object):
    id = 1
    {%- for stream in streams %}
    {{stream.identifier}}_factory = None
    {%- endfor %}

    def __init__(self, transport):
        self.transport = transport
        self.source_streams = {}
        return

    def __del__(self):
        for id,stream in self.source_streams.items():
            if stream.delete != None:
                stream.delete()
        self.source_streams = {}
        return

    def write_message(self, message):
        self.transport.write(message.serialize())

    {% for stream in streams %}
    def set_{{stream.identifier}}_factory(create):
        Router.{{stream.identifier}}_factory = create

    def create_stream_{{stream.identifier}}(self, stream_id, factory):
        subscribe, delete = factory()
        stream = SourceStream(stream_id, delete)
        self.source_streams[stream_id] = stream
        self.ack_create(stream_id)
        subscribe(
            lambda item: self.{{stream.identifier}}_next(stream, item),
            lambda: self.{{stream.identifier}}_completed(stream),
            lambda message: self.{{stream.identifier}}_error(stream, message)
        )

    def {{stream.identifier}}_next(self, subscription, item):
        msg = ItemNextMessage(subscription.id, item)
        self.write_message(msg)
        return
    def {{stream.identifier}}_completed(self, subscription):
        msg = ItemCompletedMessage(subscription.id)
        self.write_message(msg)
        return
    def {{stream.identifier}}_error(self, subscription, message):
        msg = ItemErrorMessage(subscription.id, message)
        self.write_message(msg)
        return

    {% endfor %}

    def on_create_message(self, message):
        {%- for stream in streams %}
        {% if not loop.first %}el{% endif%}if message.stream_type == '{{stream.identifier}}':
            if Router.{{stream.identifier}}_factory == None:
                raise NoFactory("no factory for stream {{stream.identifier}}")
            self.create_stream_{{stream.identifier}}(message.stream_id, Router.{{stream.identifier}}_factory)
        {%- endfor %}


    def on_delete_message(self, id):
        if id in self.source_streams:
            stream = self.source_streams[id]
            if stream.delete != None:
                stream.delete()
            del self.source_streams[id]

    def ack_create(self, id):
        msg = CreateAckMessage(id)
        self.transport.write(msg.to_json())

    def on_message(self, msg):
        message = msg_from_json(msg)
        if message.what == 'create':
            self.on_create_message(message)
        elif message.what == 'delete':
            self.on_delete_message(message.stream_id)

        return
