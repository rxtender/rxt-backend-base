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
        print('Data received: {!r}'.format(message))

        self.frame_context, packets = unframe(self.frame_context, message)
        for packet in packets:
            self.router.on_message(packet)

def count_items(observer):
    for tick in range(0,10):
        print('pushing value {0}'.format(tick))
        observer.on_next(CounterItem(tick))
    observer.on_completed()


class ForwardObserver(Observer):
    def __init__(self, next, completed, error):
        super().__init__()
        self.next = next
        self.completed = completed
        self.error = error

    def on_next(self, value):
        print("Forwarding {0}".format(value.value))
        self.next(value)

    def on_completed(self):
        print("Done!")
        self.completed()

    def on_error(self, error):
        print("Error Occurred: {0}".format(error))
        self.error(error)

def delete_counter_subscription(stream):
    stream = None

def create_counter_stream():
    source = Observable.create(count_items)
    return lambda n,c,e: subscribe_counter_stream(source, n, c, e), lambda: delete_counter_subscription(source)

def subscribe_counter_stream(stream, next, completed, error):
    stream.subscribe(ForwardObserver(next, completed, error))

Router.set_Counter_factory(create_counter_stream)

loop = asyncio.get_event_loop()
# Each client connection will create a new protocol instance
coro = loop.create_server(CounterServerProtocol, '127.0.0.1', 9999)
server = loop.run_until_complete(coro)

# Serve requests until Ctrl+C is pressed
print('Serving on {}'.format(server.sockets[0].getsockname()))
try:
    loop.run_forever()
except KeyboardInterrupt:
    pass

# Close the server
server.close()
loop.run_until_complete(server.wait_closed())
loop.close()
