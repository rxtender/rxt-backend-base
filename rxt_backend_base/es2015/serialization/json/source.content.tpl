
{%- for item in items %}

function {{item.identifier}}({%- for field in item.field %}{{field.identifier}} {% if not loop.last %},{% endif%} {%- endfor %}) {
  return {
  {%- for field in item.field %}
    "{{ field.identifier }}": {{ field.identifier }}{% if not loop.last %},{% endif%}
  {%- endfor %}
  };
}

function {{item.identifier}}_deserialize(in_obj_repr):
    in_obj = JSON.parse(in_obj_repr)
    return {{item.identifier}}({%- for field in item.field %}in_obj.{{field.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %})

function {{item.identifier}}_serialize(in_obj):
    return JSON.stringify(in_obj)

{%- endfor %}

function create_message(stream_type) {
  msg = {
    'what': 'create',
    'streamType' : stream_type
  };

  msg.toJson = function() {
      return JSON.Stringify(msg);
  };
  return msg;
}

function ack_message(stream_id) {
  msg = {
    'what': 'createAck',
    'streamId' : stream_id
  };

  msg.to_json = function() {
      JSON.Stringify(msg);
  };
  return msg;
}

function msg_from_json(in_msg_json) {
    in_msg = JSON.parse(in_msg_json);
    out_msg = null;
    what = in_msg.what;
    if what == 'next' {
        {%- for stream in streams %}
        {% if not loop.first %}else {% endif%}if in_msg.streamType == '{{stream.identifier}}':
            out_msg = next_message('{{stream.identifier}}');
        {%- endfor %}
        else:
            throw 'invalid stream type';
    }
    else if(what == 'createAck') {
        out_msg = ack_message(in_msg.streamId);
    }
    else {
        throw 'Invalid message type';
    }

    return out_msg;
}
