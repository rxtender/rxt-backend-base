from unittest import TestCase
import json

from .base_stream_rxt import Router, CreateMessage, CounterItem

class TestTransport(object):
    def __init__(self):
        self.buffer = None
    def write(self, data):
        self.buffer = data

class TestFactory(object):
    def __init__(self):
        self.created = False
        self.forward_next = None
        self.forward_completed = None
        self.forward_error = None
        return

    def create_counter_subscription(self, next, completed, error, unsubscribe):
        self.created = True
        self.forward_next = next
        self.forward_completed = completed
        self.forward_error = error
        return lambda: self.delete_counter_subscription(73)

    def delete_counter_subscription(self, subsciption_id):
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
        Router.set_Counter_factory(
            self.factory.create_counter_subscription,
            self.factory.delete_counter_subscription)
        self.router = Router(self.transport)
        self.router.on_message(
            CreateMessage('Counter', id).serialize())


class BaseStreamTestCase(TestCase):

    def test_create_stream(self):
        transport = TestTransport()
        factory = TestFactory()
        Router.set_Counter_factory(
            factory.create_counter_subscription,
            factory.delete_counter_subscription)
        router = Router(transport)
        router.on_message(
            CreateMessage('Counter', 42).serialize())
        self.assertEqual(
            json.loads('{"streamId": 42, "what": "createAck"}'),
            json.loads(transport.buffer))
        self.assertEqual(True, factory.created)

    def test_next(self):
        context = TestContext(42)
        context.factory.next(CounterItem(142))
        self.assertEqual(
            json.loads('{\"streamId\": 42, "item": {"value": 142}, "what": "item"}'),
            json.loads(context.transport.buffer))

        context.factory.next(CounterItem(28))
        self.assertEqual(
            json.loads('{\"streamId\": 42, "item": {"value": 28}, "what": "item"}'),
            json.loads(context.transport.buffer))

        context.factory.next(CounterItem(72))
        self.assertEqual(
            json.loads('{\"streamId\": 42, "item": {"value": 72}, "what": "item"}'),
            json.loads(context.transport.buffer))

    def test_completed(self):
        context = TestContext(42)
        context.factory.completed()
        self.assertEqual(
            json.loads('{\"streamId\": 42, "what": "completed"}'),
            json.loads(context.transport.buffer))

    def test_error(self):
        context = TestContext(42)
        message = "i am lost"
        context.factory.error(message)
        self.assertEqual(
            json.loads('{\"streamId\": 42, "what": "error", "message": "' + message + '"}'),
            json.loads(context.transport.buffer))
