
class TestTransport(object):
    def __init__(self):
        self.buffer = None
    def write(self, data):
        self.buffer = data
