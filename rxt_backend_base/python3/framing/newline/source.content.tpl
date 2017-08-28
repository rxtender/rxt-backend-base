
def frame(data):
    if '\n' in data:
      raise ValueError('newline must be escaped')
    return data + '\n'

def unframe(context, data):
    lines = data.split('\n')
    lines[0] = context + lines[0]
    context = lines[-1]
    packets = lines[0:-1]
    return context, packets
