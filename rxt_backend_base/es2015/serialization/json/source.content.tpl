
{%- for struct in structs %}

function {{struct.identifier}}({%- for field in struct.field %}{{field.identifier}} {% if not loop.last %},{% endif%} {%- endfor %}) {
  const args = Array.from(arguments);
  if(args.length != {{struct.field|length}})
    throw new Error('bad number of argument');
  return {
  {%- for field in struct.field %}
    "{{ field.identifier }}": {{ field.identifier }}{% if not loop.last %},{% endif%}
  {%- endfor %}
  };
}

function {{struct.identifier}}_deserialize(in_obj_repr) {
  try {
    const inObj = JSON.parse(in_obj_repr)

    {%- for field in struct.field %}
    if(inObj.{{ field.identifier }} == undefined)
      return null;
    {%- endfor %}

    return {{struct.identifier}}({%- for field in struct.field %}inObj.{{field.identifier}}{% if not loop.last %}, {% endif%}{%- endfor %});
  } catch(e) {
    return null;
  }

}

function {{struct.identifier}}_serialize(inObj) {
  {%- for field in struct.field %}
  if(inObj.{{ field.identifier }} == undefined)
    return null;
  {%- endfor %}

  return JSON.stringify(inObj, [{%- for field in struct.field %}"{{field.identifier}}"{% if not loop.last %}, {% endif%}{%- endfor %}]);
}

function {{struct.identifier}}Message(obj) {
  let msg = {
    'what': 'create',
    'item' : obj
  };

  msg.toJson = () => {
    return JSON.stringify(msg, (k,v) => {
      switch(k) {
        case 'what': return v;
        case 'item': return {{struct.identifier}}_serialize(obj);
      }
      return undefined;
    });
  };
  return msg;
}

{%- endfor %}

function createMessage(streamType, streamId, args) {
  let msg = {
    'what': 'create',
    'streamType' : streamType,
    'streamId': streamId,
    'args': args
  };

  msg.toJson = function() {
    return JSON.stringify(msg, ['what', 'streamType', 'streamId', 'args']);
  };
  return msg;
}

function ackMessage(streamId) {
  let msg = {
    'what': 'createAck',
    'streamId' : streamId
  };

  msg.toJson = function() {
    JSON.stringify(msg, ['what', 'streamId']);
  };
  return msg;
}

function nackMessage(streamId) {
  let msg = {
    'what': 'createNack',
    'streamId' : streamId
  };

  msg.toJson = function() {
    JSON.stringify(msg, ['what', 'streamId']);
  };
  return msg;
}

function deleteMessage(streamId) {
  let msg = {
    'what': 'delete',
    'streamId': streamId
  };

  msg.toJson = function() {
    return JSON.stringify(msg, ['what', 'streamId']);
  };
  return msg;
}

function deleteAckMessage(streamId) {
  let msg = {
    'what': 'deleteAck',
    'streamId' : streamId
  };

  msg.toJson = function() {
    JSON.stringify(msg, ['what', 'streamId']);
  };
  return msg;
}

function nextMessage(streamId, obj) {
  let msg = {
    'what': 'next',
    'streamId': streamId,
    'item': obj
  };

  return msg;
}

function completedMessage(streamId) {
  let msg = {
    'what': 'completed',
    'streamId': streamId
  };

  msg.toJson = function() {
    JSON.stringify(msg, ['what', 'streamId']);
  };
  return msg;
}

function errorMessage(streamId, obj) {
  let msg = {
    'what': 'error',
    'streamId': streamId,
    'error': obj
  };

  msg.toJson = function() {
    JSON.stringify(msg, ['what', 'streamId', 'message']);
  };
  return msg;
}

function createSinkMessage(streamType, observer, args) {
  return {
    'what': 'createSink',
    'streamType' : streamType,
    'observer': observer,
    'args': args
  };
}

function deleteSinkMessage(observer) {
  return {
    'what': 'deleteSink',
    'observer': observer
  };
}

function msgFromJson(in_msg_json) {
  const in_msg = JSON.parse(in_msg_json);
  let out_msg = null;
  const what = in_msg.what;
  if(what == 'next') {
    out_msg = nextMessage(in_msg.streamId, in_msg.item);
  }
  else if(what == 'completed') {
    out_msg = completedMessage(in_msg.streamId);
  }
  else if(what == 'error') {
    out_msg = errorMessage(in_msg.streamId, in_msg.message);
  }
  else if(what == 'createAck') {
    out_msg = ackMessage(in_msg.streamId);
  }
  else if(what == 'createNack') {
    out_msg = nackMessage(in_msg.streamId);
  }
  else if(what == 'deleteAck') {
    out_msg = deleteAckMessage(in_msg.streamId);
  }
  else {
    throw 'Invalid message type';
  }

  return out_msg;
}
