import unittest
from audit_prayer_catalog import records


class PrayerInventoryTest(unittest.TestCase):
    def test_short_prayers_are_not_lost(self):
        self.assertEqual(len(list(records(['Señor, dame paz.', 'Gracias, Señor.']))), 2)

    def test_tags_are_not_prayers(self):
        rows = list(records({'title': 'Oración', 'text': 'Texto', 'tags': ['paz', 'fe']}))
        self.assertEqual(len(rows), 1)


if __name__ == '__main__':
    unittest.main()
