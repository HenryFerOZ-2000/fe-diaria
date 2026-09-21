"""Inventory bundled JSON text records without assigning unproven authorship."""
import json
import argparse
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT_FIELDS = {'text', 'texto', 'prayer', 'oracion', 'body', 'content'}
METADATA_LISTS = {'tags', 'references', 'passages', 'sources'}

def records(value, pointer=''):
    if isinstance(value, dict):
        if any(isinstance(value.get(key), str) and value[key].strip() for key in TEXT_FIELDS):
            yield {**value, '_pointer': pointer}
        for key, child in value.items():
            if key not in METADATA_LISTS:
                escaped = key.replace('~', '~0').replace('/', '~1')
                yield from records(child, f'{pointer}/{escaped}')
    elif isinstance(value, list):
        for index, child in enumerate(value):
            if isinstance(child, str) and child.strip():
                yield {'text': child, '_pointer': f'{pointer}/{index}'}
            else:
                yield from records(child, f'{pointer}/{index}')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--details', action='store_true', help='Print JSON pointers and fingerprints, not prayer text.')
    args = parser.parse_args()
    total = 0
    fingerprints = set()
    inventory = []
    for path in sorted((ROOT / 'assets').rglob('*.json')):
        relative = path.relative_to(ROOT).as_posix()
        if not any(word in relative for word in ('prayer', 'oracion', 'tradition')):
            continue
        rows = list(records(json.loads(path.read_text(encoding='utf-8-sig'))))
        attributed = sum(bool(row.get('sourceUrl') or row.get('source_url')) for row in rows)
        total += len(rows)
        for row in rows:
            text = '\n'.join(row[k] for k in sorted(TEXT_FIELDS) if isinstance(row.get(k), str))
            fingerprint = hashlib.sha256(text.encode('utf-8')).hexdigest()
            fingerprints.add(fingerprint)
            inventory.append({
                'location': f'{relative}#{row["_pointer"]}',
                'id': row.get('id'),
                'title': row.get('title', row.get('titulo')),
                'sha256': fingerprint,
                'sourceUrl': row.get('sourceUrl', row.get('source_url')),
                'licenseStatus': row.get('licenseStatus', 'undocumented'),
                'reviewStatus': row.get('reviewStatus', 'pending'),
            })
        if not args.details:
            print(f'{relative}: {len(rows)} text records; {attributed} explicit source URLs')
    if args.details:
        print(json.dumps(inventory, ensure_ascii=True, indent=2))
    else:
        print(f'Total: {total} records; {len(fingerprints)} distinct exact text fingerprints.')
        print('Inventory only: titles, similarity and presence of URLs do not certify authorship or rights.')


if __name__ == '__main__':
    main()
