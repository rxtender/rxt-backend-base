from unittest import TestCase

from .base_stream_rxt import Router, CreateMessage

class TestTransport(object):
    def __init__(self):
        self.buffer = None
    def write(self, data):
        self.buffer = data

def create_counter_subscription(next, completed, error, unsubscribe):
    return 73
def delete_counter_subscription(subsciption_id):
    return

class BaseStreamTestCase(TestCase):

    def test_create_stream(self):
        transport = TestTransport()
        Router.set_Counter_factory(
            create_counter_subscription,
            delete_counter_subscription)
        router = Router(transport)
        router.on_message(
            CreateMessage('Counter', 42).serialize())
        self.assertEqual('{"streamId": 42, "what": "createAck"}', transport.buffer)
