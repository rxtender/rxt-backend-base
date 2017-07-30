
class SourceRouterError(Exception):
    pass


class SourceStream(object):
    def __init__(self, id, factory):
        if factory == None:
            raise SourceRouterError('No factory')
        self.id = id
        self.factory = factory
        self.stream = None

    def set_stream(self, stream):
        self.stream = stream

class SourceRouter(object):
    id = 1
    # Factory functions index
    CREATE = 0
    DELETE = 1

    def __init__(self, transport):
        self.transport = transport
        self.streams = []
        {%- for stream in streams %}
        self.{{stream.identifier}}_factory = None
        {%- endfor %}
        return

    def __del__(self):
        for stream in self.streams:
            stream.factory[SourceRouter.DELETE](stream.stream)
        streams = None
        return

    {% for stream in streams %}
    def set_{{stream.identifier}}_factory(self, create, delete):
        self.{{stream.identifier}}_factory = [create, delete]
        return

    def create_stream_{{stream.identifier}}(self):
        stream = SourceStream(SourceRouter.id, self.{{stream.identifier}}_factory)
        SourceRouter.id += 1
        stream.set_stream(stream.factory[SourceRouter.CREATE]())
        self.streams.append(stream)
        return stream.id
    {% endfor %}

    def on_create_message(self, message):
        {%- for stream in streams %}
        {% if not loop.first %}el{% endif%}if message.stream_type == '{{stream.identifier}}':
            stream_id = self.create_stream_{{stream.identifier}}()
        {%- endfor %}
        return stream_id

    def on_delete_message(self, id):
        for stream in self.streams:
            if stream.id == id:
                stream.factory[SourceRouter.DELETE].delete(stream.stream)
                self.streams.remove(stream)
                break
        return None

    def ack_create(self, id):
        msg = CreateAckMessage(id)
        print(msg.to_json())
        self.transport.write(msg.to_json())

    def on_message(self, msg):
        message = msg_from_json(msg)
        if message.what == 'create':
            stream_id = self.on_create_message(message)
            self.ack_create(stream_id)
        elif message.what == 'delete':
            self.on_delete_message(message.stream_id)

        return
