
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
{%- endfor %}

{% for stream in streams %}

export function {{stream.identifier}}NextMessage(streamId, obj) {
  let msg = {
    'what': 'next',
    'streamId': streamId,
    'item' : obj
  };

  msg.toJson = () => {
    return JSON.stringify(msg, ['what', 'streamId', 'item']);
    /*
    return JSON.stringify(msg, function(k,v) {
      switch(k) {
        case 'item': return {{stream.item_identifier}}_serialize(msg.item);
        default:
          return v;
      }
    });
    */
  };
  return msg;
}

{%- endfor %}

export function createMessage(streamType, streamId, args) {
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

export function ackMessage(streamId) {
  let msg = {
    'what': 'createAck',
    'streamId' : streamId
  };

  msg.toJson = function() {
    return JSON.stringify(msg, ['what', 'streamId']);
  };
  return msg;
}

export function nackMessage(streamId) {
  let msg = {
    'what': 'createNack',
    'streamId' : streamId
  };

  msg.toJson = function() {
    return JSON.stringify(msg, ['what', 'streamId']);
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
    return JSON.stringify(msg, ['what', 'streamId']);
  };
  return msg;
}

function nextMessage(streamId, obj) {
  let msg = {
    'what': 'next',
    'streamId': streamId,
    'item': obj
  };

  msg.toJson = function() {
    return JSON.stringify(msg);
  };
  return msg;
}

function completedMessage(streamId) {
  let msg = {
    'what': 'completed',
    'streamId': streamId
  };

  msg.toJson = function() {
    return JSON.stringify(msg, ['what', 'streamId']);
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
    return JSON.stringify(msg, ['what', 'streamId', 'message']);
  };
  return msg;
}

function createSinkMessage(linkId, streamType, observer, args) {
  return {
    'what': 'createSink',
    'linkId': linkId,
    'streamType' : streamType,
    'observer': observer,
    'args': args
  };
}

function deleteSinkMessage(linkId, observer) {
  return {
    'what': 'deleteSink',
    'linkId': linkId,
    'observer': observer
  };
}

function addLinkMessage(linkId) {
  return {
    'what': 'addLink',
    'linkId' : linkId
  };
}

function delLinkMessage(linkId) {
  return {
    'what': 'delLink',
    'linkId' : linkId
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
  else if(what == 'create') {
    out_msg = createMessage(in_msg.streamType, in_msg.streamId, in_msg.args);
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
