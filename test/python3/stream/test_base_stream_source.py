from unittest import TestCase
import json

from .base_stream_rxt import Router, CreateMessage, DeleteMessage, CounterItem

class TestTransport(object):
    def __init__(self):
        self.buffer = None
    def write(self, data):
        self.buffer = data

class TestFactory(object):
    def __init__(self):
        self.created = False
        self.deleted = False
        self.forward_next = None
        self.forward_complete = None
        self.forward_error = None
        return

    def create_counter_stream(self):
        self.created = True
        return lambda n,c,e: self.subscribe_counter_stream(n, c, e), lambda: self.delete_counter_subscription()

    def subscribe_counter_stream(self, next, complete, error):
        self.forward_next = next
        self.forward_complete = complete
        self.forward_error = error
        return lambda: self.delete_counter_subscription()

    def delete_counter_subscription(self):
        self.deleted = True
        return

    def next(self, value):
        self.forward_next(value)

    def complete(self):
        self.forward_complete()

    def error(self, message):
        self.forward_error(message)

class TestContext(object):
    def __init__(self, id):
        self.transport = TestTransport()
        self.factory = TestFactory()
        Router.set_Counter_factory(self.factory.create_counter_stream)
        self.router = Router(self.transport)
        self.router.on_message(
            CreateMessage('Counter', id, []).serialize())

class BaseStreamTestCase(TestCase):

    def test_create_stream(self):
        transport = TestTransport()
        factory = TestFactory()
        Router.set_Counter_factory(factory.create_counter_stream)
        router = Router(transport)
        router.on_message(
            CreateMessage('Counter', 42, []).serialize())
        self.assertEqual(
            json.loads('{"streamId": 42, "what": "createAck"}'),
            json.loads(transport.buffer))
        self.assertEqual(True, factory.created)

    def test_delete(self):
        context = TestContext(42)
        context.router.on_message(
            DeleteMessage(42).serialize())
        self.assertEqual(True, context.factory.deleted)

    def test_next(self):
        context = TestContext(42)
        context.factory.next(CounterItem(142))
        self.assertEqual(
            json.loads('{\"streamId\": 42, "item": {"value": 142}, "what": "next"}'),
            json.loads(context.transport.buffer))

        context.factory.next(CounterItem(28))
        self.assertEqual(
            json.loads('{\"streamId\": 42, "item": {"value": 28}, "what": "next"}'),
            json.loads(context.transport.buffer))

        context.factory.next(CounterItem(72))
        self.assertEqual(
            json.loads('{\"streamId\": 42, "item": {"value": 72}, "what": "next"}'),
            json.loads(context.transport.buffer))

    def test_complete(self):
        context = TestContext(42)
        context.factory.complete()
        self.assertEqual(
            json.loads('{\"streamId\": 42, "what": "complete"}'),
            json.loads(context.transport.buffer))

    def test_error(self):
        context = TestContext(42)
        message = "i am lost"
        context.factory.error(message)
        self.assertEqual(
            json.loads('{\"streamId\": 42, "what": "error", "message": "' + message + '"}'),
            json.loads(context.transport.buffer))
