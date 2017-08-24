{%- for item in items %}

class {{ item.identifier }}(object):
    def __init__(self {%- for field in item.field %}, {{field.identifier}} {%- endfor %}):
        {%- for field in item.field %}
        self.{{ field.identifier }} = {{ field.identifier }}
        {%- endfor %}


def {{item.identifier}}_deserialize(in_obj_repr):
    in_obj = json.loads(in_obj_repr)

    {%- for field in item.field %}
    if not '{{ field.identifier }}' in in_obj:
        return None
    {%- endfor %}

    return {{item.identifier}}({%- for field in item.field %}in_obj['{{field.identifier}}']{% if not loop.last %}, {% endif%}{%- endfor %})

def {{item.identifier}}_serialize(in_obj):
    return json.dumps({
        {%- for field in item.field %}
        '{{ field.identifier }}' : in_obj.{{ field.identifier }}{% if not loop.last %}, {% endif%}
        {%- endfor %}
    })

{%- endfor %}

class Message(object):
    def __init__(self, what):
        self.what = what

class CreateMessage(Message):
    def __init__(self, stream_type):
        super().__init__('create')
        self.stream_type = stream_type

class DeleteMessage(Message):
    def __init__(self, stream_id):
        super().__init__('delete')
        self.stream_id = stream_id


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

def msg_from_json(in_msg_json):
    in_msg = json.loads(in_msg_json)
    out_msg = None
    what = in_msg['what']
    '''
    if what == 'create':
        {% if streams %}
        {%- for stream in streams %}
        {% if not loop.first %}el{% endif%}if in_msg['streamType'] == '{{stream.identifier}}':
            out_msg = CreateMessage('{{stream.identifier}}')
        {%- endfor %}
        else:
            raise InvalidRequest('invalid stream type')
        {% endif %}
    '''
    if what == 'delete':
        out_msg = DeleteMessage(in_msg['streamId'])
    else:
        raise InvalidRequest('Invalid message type')

    return out_msg # todo raise exception

{%- for stream in streams %}

class {{ stream.identifier }}(object):
    def __init__(self {%- for field in stream.field %}, {{field.identifier}} {%- endfor %}):
        {%- for field in stream.field %}
        self.{{ field.identifier }} = {{ field.identifier }}
        {%- endfor %}


def stream_{{stream.identifier}}_from_json(in_obj_repr):
    in_obj = json.loads(in_obj_repr)
    out_obj = {{identifier}}({%- for field in stream.field %}in_obj['{{field.identifier}}']{% if not loop.last %}, {% endif%}{%- endfor %})
    return out_obj

def stream_{{stream.identifier}}_to_json(in_obj):
    return = json.dumps(in_obj)

{%- endfor %}
