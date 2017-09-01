from unittest import TestCase
import json

from .arg_stream_rxt import Router, CreateMessage, DeleteMessage, CounterItem
from .test_utils import TestTransport

class TestFactory(object):
    def __init__(self):
        self.created = False
        self.deleted = False
        self.forward_next = None
        self.forward_completed = None
        self.forward_error = None
        self.arg_start = None
        self.arg_end = None
        self.arg_step = None
        return

    def create_counter_stream(self, start, end, step):
        self.created = True
        self.arg_start = start
        self.arg_end = end
        self.arg_step = step
        return lambda n,c,e: self.subscribe_counter_stream(n, c, e), lambda: self.delete_counter_subscription()

    def subscribe_counter_stream(self, next, completed, error):
        self.forward_next = next
        self.forward_completed = completed
        self.forward_error = error
        return lambda: self.delete_counter_subscription()

    def delete_counter_subscription(self):
        self.deleted = True
        return

    def next(self, value):
        self.forward_next(value)

    def completed(self):
        self.forward_completed()

    def error(self, message):
        self.forward_error(message)

class TestContext(object):
    def __init__(self, id):
        self.transport = TestTransport()
        self.factory = TestFactory()
        Router.set_Counter_factory(self.factory.create_counter_stream)
        self.router = Router(self.transport)

class BaseStreamTestCase(TestCase):

    def test_create_arg_stream(self):
        transport = TestTransport()
        factory = TestFactory()
        Router.set_Counter_factory(factory.create_counter_stream)
        router = Router(transport)
        router.on_message(
            CreateMessage('Counter', 42, [0, 10, 1]).serialize())
        self.assertEqual(
            json.loads('{"streamId": 42, "what": "createAck"}'),
            json.loads(transport.buffer))
        self.assertEqual(True, factory.created)
        self.assertEqual(0, factory.arg_start)
        self.assertEqual(10, factory.arg_end)
        self.assertEqual(1, factory.arg_step)
