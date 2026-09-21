import json
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

from tools.generate_android_widget_catalog import build_catalog, encode_catalog


class AndroidWidgetCatalogTest(unittest.TestCase):
    def test_committed_catalog_matches_current_sources(self):
        root = Path(__file__).resolve().parents[1]
        expected = encode_catalog(
            build_catalog(
                root / "assets/data/daily_verses_refs.json",
                root / "assets/db/rv1909.sqlite",
                root / "lib/bible/domain/bible_book_info.dart",
            )
        )
        actual = (
            root
            / "android/app/src/main/res/raw/daily_verses_rv1909.json"
        ).read_text(encoding="utf-8")

        self.assertEqual(actual, expected)

    def test_preserves_reference_order_and_exact_rv1909_text(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            refs = root / "refs.json"
            db = root / "rv.sqlite"
            books = root / "books.dart"
            refs.write_text(
                json.dumps(
                    [
                        {"book": "PSA", "chapter": 23, "verse": 1},
                        {"book": "JHN", "chapter": 3, "verse": 16},
                    ]
                ),
                encoding="utf-8",
            )
            books.write_text(
                "BibleBookInfo(id: 'PSA', name: 'Salmos', section: 'x', "
                "testament: BibleTestament.old),\n"
                "BibleBookInfo(id: 'JHN', name: 'Juan', section: 'x', "
                "testament: BibleTestament.newTestament),",
                encoding="utf-8",
            )
            with closing(sqlite3.connect(db)) as connection:
                connection.execute(
                    "CREATE TABLE verses("
                    "book TEXT, chapter INTEGER, verse INTEGER, text TEXT)"
                )
                connection.executemany(
                    "INSERT INTO verses VALUES (?, ?, ?, ?)",
                    [
                        (
                            "PSA",
                            23,
                            1,
                            "Jehová es mi pastor; nada me faltará.",
                        ),
                        (
                            "JHN",
                            3,
                            16,
                            "Porque de tal manera amó Dios al mundo...",
                        ),
                    ],
                )
                connection.commit()

            records = build_catalog(refs, db, books)
            repeated = build_catalog(refs, db, books)

            self.assertEqual(
                [record["reference"] for record in records],
                ["Salmos 23:1", "Juan 3:16"],
            )
            self.assertEqual(
                records[0]["text"],
                "Jehová es mi pastor; nada me faltará.",
            )
            self.assertEqual(encode_catalog(records), encode_catalog(repeated))

    def test_rejects_a_reference_missing_from_rv1909(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "refs.json").write_text(
                '[{"book":"JHN","chapter":3,"verse":16}]',
                encoding="utf-8",
            )
            (root / "books.dart").write_text(
                "BibleBookInfo(id: 'JHN', name: 'Juan',",
                encoding="utf-8",
            )
            with closing(sqlite3.connect(root / "rv.sqlite")) as connection:
                connection.execute(
                    "CREATE TABLE verses("
                    "book TEXT, chapter INTEGER, verse INTEGER, text TEXT)"
                )
                connection.commit()

            with self.assertRaisesRegex(ValueError, "JHN 3:16"):
                build_catalog(
                    root / "refs.json",
                    root / "rv.sqlite",
                    root / "books.dart",
                )

    def test_rejects_undeclared_duplicate_references(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            duplicate = {"book": "JHN", "chapter": 3, "verse": 16}
            (root / "refs.json").write_text(
                json.dumps([duplicate, duplicate]),
                encoding="utf-8",
            )
            (root / "books.dart").write_text(
                "BibleBookInfo(id: 'JHN', name: 'Juan',",
                encoding="utf-8",
            )
            with closing(sqlite3.connect(root / "rv.sqlite")) as connection:
                connection.execute(
                    "CREATE TABLE verses("
                    "book TEXT, chapter INTEGER, verse INTEGER, text TEXT)"
                )
                connection.execute(
                    "INSERT INTO verses VALUES ('JHN', 3, 16, 'Texto')"
                )
                connection.commit()

            with self.assertRaisesRegex(ValueError, "duplicada"):
                build_catalog(
                    root / "refs.json",
                    root / "rv.sqlite",
                    root / "books.dart",
                )

    def test_preserves_the_known_psalm_121_8_repeat(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repeated = {"book": "PSA", "chapter": 121, "verse": 8}
            (root / "refs.json").write_text(
                json.dumps([repeated, repeated]),
                encoding="utf-8",
            )
            (root / "books.dart").write_text(
                "BibleBookInfo(id: 'PSA', name: 'Salmos',",
                encoding="utf-8",
            )
            with closing(sqlite3.connect(root / "rv.sqlite")) as connection:
                connection.execute(
                    "CREATE TABLE verses("
                    "book TEXT, chapter INTEGER, verse INTEGER, text TEXT)"
                )
                connection.execute(
                    "INSERT INTO verses VALUES "
                    "('PSA', 121, 8, 'Jehová guardará tu salida.')"
                )
                connection.commit()

            records = build_catalog(
                root / "refs.json",
                root / "rv.sqlite",
                root / "books.dart",
            )

            self.assertEqual(len(records), 2)
            self.assertEqual(
                [record["reference"] for record in records],
                ["Salmos 121:8", "Salmos 121:8"],
            )


if __name__ == "__main__":
    unittest.main()
