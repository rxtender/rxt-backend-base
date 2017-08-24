from unittest import TestCase

from .base_type_rxt import SingleField, SingleField_deserialize, SingleField_serialize,MultiFields

class BaseTypeSerializationTestCase(TestCase):

    def test_create_SingleField_object(self):
        item = SingleField(42)
        self.assertEqual(42, item.foo32)
