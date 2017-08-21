
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

function createMessage(streamType, streamId) {
  let msg = {
    'what': 'create',
    'streamType' : streamType,
    'streamId': streamId
  };

  msg.toJson = function() {
    return JSON.stringify(msg);
  };
  return msg;
}

function ackMessage(streamId) {
  let msg = {
    'what': 'createAck',
    'streamId' : streamId
  };

  msg.toJson = function() {
    JSON.stringify(msg);
  };
  return msg;
}

function nackMessage(streamId) {
  let msg = {
    'what': 'createNack',
    'streamId' : streamId
  };

  msg.toJson = function() {
    JSON.stringify(msg);
  };
  return msg;
}

function msgFromJson(in_msg_json) {
  const in_msg = JSON.parse(in_msg_json);
  let out_msg = null;
  const what = in_msg.what;
  if(what == 'next') {
    {%- if streams %}
    {%- for stream in streams %}
    {% if not loop.first %}else {% endif%}if(in_msg.streamType == '{{stream.identifier}}') {
      out_msg = nextMessage('{{stream.identifier}}');
    }
    {%- endfor %}
    else
      throw 'invalid stream type';
    {%- endif %}
  }
  else if(what == 'createAck') {
    out_msg = ackMessage(in_msg.streamId);
  }
  else if(what == 'createNack') {
    out_msg = nackMessage(in_msg.streamId);
  }

  else {
    throw 'Invalid message type';
  }

  return out_msg;
}
