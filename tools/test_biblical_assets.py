import sqlite3
import unittest
from sync_biblical_assets import parse_reference, passage_text


class BiblicalAssetsTest(unittest.TestCase):
    def test_disjoint_psalms_keep_both_ranges(self):
        self.assertEqual(parse_reference('Salmos 106:1, 117:1-2', {'Salmos': 'PSA'}),
                         [('PSA', 106, 1, 1), ('PSA', 117, 1, 2)])

    def test_invalid_range_or_book_is_rejected(self):
        for reference in ('Salmo 23:6-1', 'Salmo 23:0', 'Otro 1:1'):
            with self.assertRaises(ValueError):
                parse_reference(reference, {'Salmo': 'PSA'})

    def test_missing_middle_verse_is_not_silently_shortened(self):
        with sqlite3.connect(':memory:') as db:
            db.execute('CREATE TABLE verses(book TEXT, chapter INTEGER, verse INTEGER, text TEXT)')
            db.executemany('INSERT INTO verses VALUES (?, ?, ?, ?)',
                           [('PSA', 23, 1, 'first'), ('PSA', 23, 3, 'third')])
            with self.assertRaises(ValueError):
                passage_text(db, [('PSA', 23, 1, 3)])
            self.assertEqual(passage_text(db, [('PSA', 23, 1, 1)]), 'first')


if __name__ == '__main__':
    unittest.main()
