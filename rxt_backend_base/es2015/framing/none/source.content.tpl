
export function frame(data) {
  return data;
}

export function unframe(context, data) {
  return {'context':context, 'packets': [data] };
}
