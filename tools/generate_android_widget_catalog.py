from __future__ import annotations

import argparse
import json
import re
import sqlite3
from contextlib import closing
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REFS = ROOT / "assets/data/daily_verses_refs.json"
DEFAULT_DB = ROOT / "assets/db/rv1909.sqlite"
DEFAULT_BOOKS = ROOT / "lib/bible/domain/bible_book_info.dart"
DEFAULT_OUTPUT = ROOT / "android/app/src/main/res/raw/daily_verses_rv1909.json"
ALLOWED_DUPLICATE_COUNTS = {("PSA", 121, 8): 2}


def _book_names(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    return dict(re.findall(r"id: '([^']+)',\s+name: '([^']+)'", text))


def build_catalog(
    refs_path: Path,
    db_path: Path,
    books_path: Path,
) -> list[dict[str, object]]:
    refs = json.loads(refs_path.read_text(encoding="utf-8"))
    names = _book_names(books_path)
    if not isinstance(refs, list) or not refs:
        raise ValueError("El catálogo diario está vacío")

    records: list[dict[str, object]] = []
    seen: dict[tuple[str, int, int], int] = {}
    database_uri = f"file:{db_path.as_posix()}?mode=ro"
    with closing(sqlite3.connect(database_uri, uri=True)) as connection:
        for position, ref in enumerate(refs):
            if not isinstance(ref, dict):
                raise ValueError(
                    f"Referencia inválida en posición {position}: {ref}"
                )
            book = ref.get("book")
            chapter = ref.get("chapter")
            verse = ref.get("verse")
            if (
                book not in names
                or not isinstance(chapter, int)
                or not isinstance(verse, int)
            ):
                raise ValueError(
                    f"Referencia inválida en posición {position}: {ref}"
                )

            key = (book, chapter, verse)
            seen[key] = seen.get(key, 0) + 1
            if seen[key] > ALLOWED_DUPLICATE_COUNTS.get(key, 1):
                raise ValueError(
                    f"Referencia duplicada: {book} {chapter}:{verse}"
                )

            row = connection.execute(
                "SELECT text FROM verses "
                "WHERE book = ? AND chapter = ? AND verse = ?",
                (book, chapter, verse),
            ).fetchone()
            if row is None or not str(row[0]).strip():
                raise ValueError(
                    f"No existe texto RV1909 para {book} {chapter}:{verse}"
                )

            text = re.sub(r"\s+", " ", str(row[0])).strip()
            records.append(
                {
                    "bookId": book,
                    "bookName": names[book],
                    "chapter": chapter,
                    "verse": verse,
                    "reference": f"{names[book]} {chapter}:{verse}",
                    "text": text,
                    "edition": "RV1909",
                }
            )

    return records


def encode_catalog(records: list[dict[str, object]]) -> str:
    return json.dumps(
        records,
        ensure_ascii=False,
        separators=(",", ":"),
    ) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    records = build_catalog(DEFAULT_REFS, DEFAULT_DB, DEFAULT_BOOKS)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        encode_catalog(records),
        encoding="utf-8",
        newline="\n",
    )
    print(f"Generated {len(records)} records at {args.output}")


if __name__ == "__main__":
    main()
