"""Mechanical synchronization of scripture copies from the reviewed local RV1909.

Default is read-only verification. --apply replaces text/edition/reference metadata,
never IDs, categories, ordering, user data or SQLite. All references are validated
before any file is written. The original bundled copies remain in Git history.
"""
import argparse
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'https://ebible.org/spaRV1909/copyright.htm'


def parse_reference(reference, names):
    match = re.fullmatch(r'(.+?)\s+(\d+:\d+(?:[-–]\d+)?(?:,\s*\d+:\d+(?:[-–]\d+)?)*)', reference)
    if not match or match[1] not in names:
        raise ValueError(f'Unrecognized reference: {reference}')
    book = names[match[1]]
    result = []
    for part in match[2].split(','):
        chapter, first, last = re.fullmatch(r'\s*(\d+):(\d+)(?:[-–](\d+))?', part).groups()
        first, last = int(first), int(last or first)
        if first < 1 or last < first:
            raise ValueError(f'Invalid range: {reference}')
        result.append((book, int(chapter), first, last))
    return result


def passage_text(db, passages):
    blocks = []
    for book, chapter, first, last in passages:
        rows = db.execute(
            'SELECT verse, text FROM verses WHERE book=? AND chapter=? AND verse BETWEEN ? AND ? ORDER BY verse',
            (book, chapter, first, last),
        ).fetchall()
        if [r[0] for r in rows] != list(range(first, last + 1)):
            raise ValueError(f'Incomplete passage: {book} {chapter}:{first}-{last}')
        blocks.append(' '.join(r[1] for r in rows))
    return '\n\n'.join(blocks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    catalog = (ROOT / 'lib/bible/domain/bible_book_info.dart').read_text(encoding='utf-8')
    names = {name: book for book, name in re.findall(r"id: '([^']+)',\s+name: '([^']+)'", catalog)}
    names['Salmo'] = 'PSA'
    paths = [ROOT / 'assets/data/verses.json', ROOT / 'assets/data/psalms.json',
             *sorted((ROOT / 'assets/verses').glob('*.json'))]
    pending = []
    total = 0
    with sqlite3.connect(f'file:{(ROOT / "assets/db/rv1909.sqlite").as_posix()}?mode=ro', uri=True) as db:
        for path in paths:
            data = json.loads(path.read_text(encoding='utf-8-sig'))
            before = json.dumps(data, ensure_ascii=False)
            for row in data:
                passages = parse_reference(row['reference'], names)
                row['text'] = passage_text(db, passages)
                row['translation'] = 'Reina-Valera 1909'
                row['sourceUrl'] = SOURCE
                row['contentKind'] = 'bible_passage'
                row['licenseStatus'] = 'public_domain'
                row['reviewStatus'] = 'matched_local_rv1909'
                row['editorialVersion'] = '2026-09-20'
                row['passages'] = [dict(book=b, chapter=c, verseStart=f, verseEnd=l) for b, c, f, l in passages]
                # Legacy consumers read a starting verse; the full range remains explicit.
                row['book'], row['chapter'], row['verse'], row['verseEnd'] = passages[0]
                total += 1
            if json.dumps(data, ensure_ascii=False) != before:
                pending.append((path, data))
    print(f'{total} biblical records checked; {len(pending)} files need synchronization.')
    if args.apply:
        for path, data in pending:
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            print(f'Updated {path.relative_to(ROOT).as_posix()}')
    elif pending:
        raise SystemExit('FAIL: scripture copies differ from the reviewed edition; run --apply after review.')


if __name__ == '__main__':
    main()
