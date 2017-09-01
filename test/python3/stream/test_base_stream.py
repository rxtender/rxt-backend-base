from unittest import TestCase

from .base_stream_rxt import Router

class TestTransport(object):
    def __init__(self):
        self.buffer = None
    def write(data):
        self.buffer = data

class BaseStreamTestCase(TestCase):

    def test_create_router(self):
        router = Router(TestTransport())
        self.assertIsNot(router, None)
