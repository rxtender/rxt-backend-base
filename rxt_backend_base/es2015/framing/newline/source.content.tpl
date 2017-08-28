
function frame(data) {
  if(data.indexOf('\n') != -1)
    throw new Error('newline must be escaped');
  return data + '\n';
}

function unframe(context, data) {
  const lines = data.split('\n');
  lines[0] = context + lines[0];

  const packets = lines.slice(0,-1);
  if(data[data.length-1] != '\n') {
    context = lines[lines.length-1];
  } else {
    context = '';
  }

  return {'context':context, 'packets':packets };
}
