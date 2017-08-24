from unittest import TestCase

from .base_type_rxt import SingleField, SingleField_deserialize, SingleField_serialize,MultiFields

class BaseTypeSerializationTestCase(TestCase):

    def test_create_SingleField(self):
        item = SingleField(42)
        self.assertEqual(42, item.foo32)

    def test_create_MultiFields(self):
        item = MultiFields(1 ,2 ,3 ,4 ,True ,1.2, "baz")
        self.assertEqual(1, item.foo32)
        self.assertEqual(2, item.bar32)
        self.assertEqual(3, item.foo64)
        self.assertEqual(4, item.bar64)
        self.assertEqual(True, item.biz)
        self.assertEqual(1.2, item.buz)
        self.assertEqual('baz', item.name)

    def test_deserialize_SingleField(self):
        itemJson = '{"foo32": 42}'
        item = SingleField_deserialize(itemJson)
        self.assertIs(type(item), SingleField)
        self.assertEqual(42, item.foo32)

    def test_deserialize_SingleField_failure(self):
        itemJson = '{}'
        item = SingleField_deserialize(itemJson)
        self.assertIs(item, None)

    def test_serialize_SingleField(self):
        expectedJson = '{"foo32": 42}'
        item = SingleField(42)
        itemJson = SingleField_serialize(item);
        self.assertEqual(expectedJson, itemJson)

    
