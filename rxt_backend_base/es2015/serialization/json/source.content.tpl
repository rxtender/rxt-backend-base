
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

function item{{item.identifier}}Message(obj) {
  let msg = {
    'what': 'create',
    'item' : obj
  };

  msg.toJson = () => {
    return JSON.stringify(msg, (k,v) => {
      switch(k) {
        case 'what': return v;
        case 'item': return {{item.identifier}}_serialize(obj);
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

function errorMessage(streamId, message) {
  let msg = {
    'what': 'error',
    'streamId': streamId,
    'message': message
  };

  msg.toJson = function() {
    JSON.stringify(msg, ['what', 'streamId', 'message']);
  };
  return msg;
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
