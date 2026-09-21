"""Read-only integrity checks for the bundled Bible and its catalog."""
import re
import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
catalog = (ROOT / 'lib/bible/domain/bible_book_info.dart').read_text(encoding='utf-8')
ids = re.findall(r"id: '([^']+)'", catalog)
with sqlite3.connect(f"file:{(ROOT / 'assets/db/rv1909.sqlite').as_posix()}?mode=ro", uri=True) as db:
    assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    actual = {row[0] for row in db.execute('SELECT DISTINCT book FROM verses')}
    assert len(ids) == len(set(ids)) == 66
    assert set(ids) == actual, (set(ids) - actual, actual - set(ids))
    assert not db.execute('SELECT book, chapter, verse FROM verses GROUP BY book, chapter, verse HAVING COUNT(*) > 1').fetchall()
    assert not db.execute("SELECT book, chapter, verse FROM verses WHERE text IS NULL OR TRIM(text) = '' OR chapter < 1 OR verse < 1").fetchall()
    for book in ids:
        chapters = [r[0] for r in db.execute('SELECT DISTINCT chapter FROM verses WHERE book = ? ORDER BY chapter', (book,))]
        assert chapters == list(range(1, max(chapters) + 1)), book
    for book, chapter, expected in [('PSA', 23, 6), ('PSA', 91, 16)]:
        rows = db.execute('SELECT verse FROM verses WHERE book = ? AND chapter = ? ORDER BY verse', (book, chapter)).fetchall()
        assert [r[0] for r in rows] == list(range(1, expected + 1))
    count = db.execute('SELECT COUNT(*) FROM verses').fetchone()[0]
    def references(value, location=''):
        if isinstance(value, dict):
            if 'book' in value and 'chapter' in value:
                yield location, value
            for key, child in value.items():
                yield from references(child, f'{location}/{key}')
        elif isinstance(value, list):
            for index, child in enumerate(value):
                yield from references(child, f'{location}/{index}')

    checked = 0
    errors = []
    for asset in sorted((ROOT / 'assets').rglob('*.json')):
        for pointer, passage in references(json.loads(asset.read_text(encoding='utf-8-sig'))):
            first = passage.get('verseStart', passage.get('verse'))
            last = passage.get('verseEnd', first)
            if not isinstance(first, int) or not isinstance(last, int):
                continue
            checked += 1
            found = [row[0] for row in db.execute(
                'SELECT verse FROM verses WHERE book = ? AND chapter = ? AND verse BETWEEN ? AND ? ORDER BY verse',
                (passage['book'], passage['chapter'], first, last),
            )]
            if first < 1 or last < first or found != list(range(first, last + 1)):
                errors.append(f'{asset.relative_to(ROOT).as_posix()}#{pointer}: {passage["book"]} {passage["chapter"]}:{first}-{last}')
    assert not errors, 'Invalid bundled references:\n' + '\n'.join(errors)
    print(f'OK: {checked} bundled passage references resolve completely in RV1909.')
    print(f'OK: 66 books, {count} verses; unique references, nonempty text, contiguous chapters, complete Psalms 23 and 91.')
    print('This verifies structure, not a line-by-line editorial collation or source provenance.')
