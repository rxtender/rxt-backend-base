from unittest import TestCase

from .dummy_type_rxt import frame, unframe

class NewlineFramingTestCase(TestCase):

    def test_frame(self):
        packet = frame('abcdef')
        self.assertEqual('abcdef\n', packet)

    def test_frame_with_newline(self):
        with self.assertRaises(ValueError):
            frame('abc\ndef')

    def test_unframe_complete(self):
        context, packets = unframe('', 'abc\n')
        self.assertEqual(1, len(packets))
        self.assertEqual('abc', packets[0])

    def test_unframe_complete_with_context(self):
        context, packets = unframe('123', 'abc\n')
        self.assertEqual(1, len(packets))
        self.assertEqual('123abc', packets[0])

    def test_unframe_partial(self):
        context, packets = unframe('', 'abc\nefg')
        self.assertEqual(1, len(packets))
        self.assertEqual('abc', packets[0])
        self.assertEqual('efg', context)

    def test_unframe_partial_with_context(self):
        context, packets = unframe('iop', 'abc\nefg')
        self.assertEqual(1, len(packets))
        self.assertEqual('iopabc', packets[0])
        self.assertEqual('efg', context)

    def test_unframe_multiple(self):
        context, packets = unframe('iop', 'abc\nefg\nhij\nklm')
        self.assertEqual(3, len(packets))
        self.assertEqual('iopabc', packets[0])
        self.assertEqual('efg', packets[1])
        self.assertEqual('hij', packets[2])
        self.assertEqual('klm', context)
