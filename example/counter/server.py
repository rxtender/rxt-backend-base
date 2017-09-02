import asyncio

from rx import Observable, Observer
from counter_rxt import frame, unframe, Router, CounterItem

class FramedTransport(object):
    def __init__(self, transport):
        self.transport = transport

    def write(self, data):
        self.transport.write(frame(data).encode())

class CounterServerProtocol(asyncio.Protocol):
    def connection_made(self, transport):
        peername = transport.get_extra_info('peername')
        print('Connection from {}'.format(peername))
        self.transport = transport
        self.router = Router(FramedTransport(transport))
        self.frame_context = ''

    def connection_lost(self, exc):
        print('connection lost')
        return

    def data_received(self, data):
        message = data.decode()
        self.frame_context, packets = unframe(self.frame_context, message)
        for packet in packets:
            self.router.on_message(packet)

def delete_counter_subscription(stream):
    stream = None

def create_counter_stream(start, end, step):
    source = Observable.from_(range(start,end+1, step)).map(
        lambda i: CounterItem(i))
    return lambda n,c,e: subscribe_counter_stream(source, n, c, e), lambda: delete_counter_subscription(source)

def subscribe_counter_stream(stream, next, completed, error):
    stream.subscribe(
        lambda i: next(i),
        lambda e: error(e),
        lambda: completed())

Router.set_Counter_factory(create_counter_stream)
loop = asyncio.get_event_loop()
# Each client connection will create a new protocol instance
coro = loop.create_server(CounterServerProtocol, '127.0.0.1', 9999)
server = loop.run_until_complete(coro)

print('Serving on {}'.format(server.sockets[0].getsockname()))
try:
    loop.run_forever()
except KeyboardInterrupt:
    pass

server.close()
loop.run_until_complete(server.wait_closed())
loop.close()
