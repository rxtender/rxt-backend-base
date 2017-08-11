
{%- for item in items %}

function {{item.identifier}}({%- for field in item.field %}{{field.identifier}} {% if not loop.last %},{% endif%} {%- endfor %}) {
  const args = Array.from(arguments);
  if(args.length != {{item.field|length}})
    throw new Error('bad number of argument');
  return {
  {%- for field in item.field %}
    "{{ field.identifier }}": {{ field.identifier }}{% if not loop.last %},{% endif%}
  {%- endfor %}
  };
}

function {{item.identifier}}_deserialize(in_obj_repr) {
  try {
    const inObj = JSON.parse(in_obj_repr)

    {%- for field in item.field %}
    if(inObj.{{ field.identifier }} == undefined)
      return null;
    {%- endfor %}

    return {{item.identifier}}({%- for field in item.field %}inObj.{{field.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %});
  } catch(e) {
    return null;
  }

}

function {{item.identifier}}_serialize(inObj) {
  {%- for field in item.field %}
  if(inObj.{{ field.identifier }} == undefined)
    return null;
  {%- endfor %}

  return JSON.stringify(inObj, [{%- for field in item.field %}"{{field.identifier}}"{% if not loop.last %}, {% endif%}{%- endfor %}]);
}

{%- endfor %}

function create_message(stream_type) {
  let msg = {
    'what': 'create',
    'streamType' : stream_type
  };

  msg.toJson = function() {
    return JSON.Stringify(msg);
  };
  return msg;
}

function ack_message(stream_id) {
  let msg = {
    'what': 'createAck',
    'streamId' : stream_id
  };

  msg.to_json = function() {
    JSON.Stringify(msg);
  };
  return msg;
}

function msg_from_json(in_msg_json) {
  const in_msg = JSON.parse(in_msg_json);
  let out_msg = null;
  const what = in_msg.what;
  if(what == 'next') {
    {%- if streams %}
    {%- for stream in streams %}
    {% if not loop.first %}else {% endif%}if(in_msg.streamType == '{{stream.identifier}}') {
      out_msg = next_message('{{stream.identifier}}');
    }
    {%- endfor %}
    else
      throw 'invalid stream type';
    {%- endif %}
  }
  else if(what == 'createAck') {
    out_msg = ack_message(in_msg.streamId);
  }
  else {
    throw 'Invalid message type';
  }

  return out_msg;
}
