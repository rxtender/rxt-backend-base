{%- for struct in structs %}

class {{ struct.identifier }}(object):
    def __init__(self {%- for field in struct.field %}, {{field.identifier}} {%- endfor %}):
        {%- for field in struct.field %}
        self.{{ field.identifier }} = {{ field.identifier }}
        {%- endfor %}

    def dict(self):
        return {
        {%- for field in struct.field %}
        '{{ field.identifier }}' : self.{{ field.identifier }}{% if not loop.last %},{% endif%}
        {%- endfor %}
        }

    def serialize(self):
        return json.dumps({
            {%- for field in struct.field %}
            '{{ field.identifier }}' : self.{{ field.identifier }}{% if not loop.last %}, {% endif%}
            {%- endfor %}
        })


def {{struct.identifier}}_deserialize(in_obj_repr):
    in_obj = json.loads(in_obj_repr)

    {%- for field in struct.field %}
    if not '{{ field.identifier }}' in in_obj:
        return None
    {%- endfor %}

    return {{struct.identifier}}({%- for field in struct.field %}in_obj['{{field.identifier}}']{% if not loop.last %}, {% endif%}{%- endfor %})

def {{struct.identifier}}_serialize(in_obj):
    return json.dumps({
        {%- for field in struct.field %}
        '{{ field.identifier }}' : in_obj.{{ field.identifier }}{% if not loop.last %}, {% endif%}
        {%- endfor %}
    })

{%- endfor %}

class Message(object):
    def __init__(self, what):
        self.what = what

class CreateMessage(Message):
    def __init__(self, stream_type, stream_id, args):
        super().__init__('create')
        self.stream_type = stream_type
        self.stream_id = stream_id
        self.args = args

    def serialize(self):
        return json.dumps({
            'what' : 'create',
            'streamType': self.stream_type,
            'streamId': self.stream_id,
            'args': self.args
        })

class DeleteMessage(Message):
    def __init__(self, stream_id):
        super().__init__('delete')
        self.stream_id = stream_id

    def serialize(self):
        return json.dumps({
            'what' : 'delete',
            'streamId': self.stream_id
        })


class CreateAckMessage(Message):
    class JsonEncoder(json.JSONEncoder):
        def default(self, obj):
            if isinstance(obj, CreateAckMessage):
                return { 'what': obj.what, 'streamId' : obj.stream_id}
            return json.JSONEncoder.default(self, obj)

    def __init__(self, stream_id):
        super().__init__('createAck')
        self.stream_id = stream_id

    def to_json(self):
        return json.dumps(self, cls=self.JsonEncoder)

class ItemNextMessage(Message):
    def __init__(self, stream_id, item):
        super().__init__('next')
        self.stream_id = stream_id
        self.item = item

    def dict(self):
        return {
            'what' : self.what,
            'streamId': self.stream_id,
            'item': self.item.dict()
        }

    def serialize(self):
        return json.dumps(self.dict())

class ItemCompleteMessage(Message):
    def __init__(self, stream_id):
        super().__init__('complete')
        self.stream_id = stream_id

    def dict(self):
        return {
            'what' : self.what,
            'streamId': self.stream_id
        }

    def serialize(self):
        return json.dumps(self.dict())

class ItemErrorMessage(Message):
    def __init__(self, stream_id, message):
        super().__init__('error')
        self.stream_id = stream_id
        self.message = message

    def dict(self):
        return {
            'what' : self.what,
            'streamId': self.stream_id,
            'message': self.message
        }

    def serialize(self):
        return json.dumps(self.dict())


def msg_from_json(in_msg_json):
    in_msg = json.loads(in_msg_json)
    out_msg = None
    what = in_msg['what']
    if what == 'create':
        {%- if streams %}
        {%- for stream in streams %}
        {% if not loop.first %}el{% endif%}if in_msg['streamType'] == '{{stream.identifier}}':
            out_msg = CreateMessage('{{stream.identifier}}', in_msg['streamId'], in_msg['args'])
        {%- endfor %}
        else:
            raise InvalidRequest('invalid stream type')
        {%- else %}
        pass
        {%- endif %}
    elif what == 'delete':
        out_msg = DeleteMessage(in_msg['streamId'])

    if out_msg == None:
        raise InvalidRequest('Invalid message type')

    return out_msg

{%- for stream in streams %}

class {{ stream.identifier }}(object):
    def __init__(self {%- for arg in stream.arg %}, {{arg.identifier}} {%- endfor %}):
        {%- for arg in stream.arg %}
        self.{{ arg.identifier }} = {{ arg.identifier }}
        {%- endfor %}
        return


def stream_{{stream.identifier}}_from_json(in_obj_repr):
    in_obj = json.loads(in_obj_repr)
    out_obj = {{stream.identifier}}({%- for arg in stream.arg %}in_obj['{{arg.identifier}}']{% if not loop.last %}, {% endif%}{%- endfor %})
    return out_obj

def stream_{{stream.identifier}}_to_json(in_obj):
    return json.dumps(in_obj)

{%- endfor %}
