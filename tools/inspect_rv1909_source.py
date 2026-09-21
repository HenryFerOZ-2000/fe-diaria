"""Compare a public-domain publisher's VPL with the existing offline asset."""
import io
import urllib.request
import zipfile
from pathlib import Path
import re
import sqlite3
import hashlib
import argparse

URL = 'https://ebible.org/Scriptures/spaRV1909_vpl.zip'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('archive', nargs='?', help='Previously downloaded publisher ZIP')
mode = parser.add_mutually_exclusive_group()
mode.add_argument('--check', action='store_true')
mode.add_argument('--synchronize', action='store_true')
args = parser.parse_args()
if args.archive:
    data = Path(args.archive).read_bytes()
else:
    with urllib.request.urlopen(URL, timeout=60) as response:
        data = response.read()
with zipfile.ZipFile(io.BytesIO(data)) as archive:
    source = archive.read('spaRV1909_vpl.txt').decode('utf-8-sig')
    rows = {}
    for line in source.splitlines():
        match = re.fullmatch(r'([A-Z0-9]{3}) (\d+):(\d+) (.*)', line)
        if not match:
            raise ValueError(f'Unexpected VPL line: {line[:40]!r}')
        book, chapter, verse, text = match.groups()
        book = {'1JO': '1JN', '2JO': '2JN', '3JO': '3JN', 'EZE': 'EZK', 'JOE': 'JOL', 'JOH': 'JHN', 'NAH': 'NAM', 'PHI': 'PHP', 'SOL': 'SNG', 'JAM': 'JAS', 'MAR': 'MRK'}.get(book, book)
        key = (book, int(chapter), int(verse))
        assert key not in rows, key
        rows[key] = text
    path = Path(__file__).resolve().parents[1] / 'assets/db/rv1909.sqlite'
    with sqlite3.connect(f'file:{path.as_posix()}?mode=ro', uri=True) as db:
        local = {(b, c, v): t for b, c, v, t in db.execute('SELECT book, chapter, verse, text FROM verses')}
    print('Source SHA256:', hashlib.sha256(data).hexdigest())
    print('Publisher verses:', len(rows), 'Local verses:', len(local))
    print('Missing locally:', sorted(rows.keys() - local.keys())[:30])
    print('Additional locally:', sorted(local.keys() - rows.keys())[:30])
    print('Source-only books:', {k[0] for k in rows} - {k[0] for k in local})
    print('Local-only books:', {k[0] for k in local} - {k[0] for k in rows})
    print('Empty source verses:', sum(not value.strip() for value in rows.values()))
    def normalize(value):
        return ' '.join(value.replace('[', '').replace(']', '').split())
    different = [k for k in rows.keys() & local.keys() if normalize(rows[k]) != normalize(local[k])]
    print('Different text after removing VPL italic brackets:', len(different), 'Sample references:', sorted(different)[:10])
    nonempty = {k for k, text in rows.items() if text.strip()}
    assert nonempty == local.keys(), 'Reference differences require editorial review; do not synchronize automatically.'
    assert len(rows) == 31102 and len(nonempty) == 31084
    if args.synchronize:
        assert hashlib.sha256(data).hexdigest() == 'e5c553f8044e676375e5f13719493f7f47c54b5f145cc33cb65f12eb6f4dc8e5', 'Unreviewed source archive'
        with sqlite3.connect(path) as db:
            for book, chapter, verse in different:
                db.execute('UPDATE verses SET text = ? WHERE book = ? AND chapter = ? AND verse = ?',
                           (normalize(rows[(book, chapter, verse)]), book, chapter, verse))
        print(f'Synchronized {len(different)} verses to the identified public-domain source. References unchanged.')
    elif args.check:
        assert not different, 'Bundled wording differs from the source'
