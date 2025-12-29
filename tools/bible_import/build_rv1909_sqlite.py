import sqlite3
import zipfile
import os
import re
from pathlib import Path

INPUT_ZIP = Path(__file__).parent / "input" / "spaRV1909_usfm.zip"
# Proyecto raíz: ../.. desde este script
PROJECT_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DB = PROJECT_ROOT / "assets" / "db" / "rv1909.sqlite"

USFM_ID_RE = re.compile(r"^\\id\s+([A-Z0-9]{3})")
USFM_CHAPTER_RE = re.compile(r"^\\c\s+(\d+)")
USFM_VERSE_RE = re.compile(r"^\\v\s+(\d+)\s+(.*)")


def clean_text(text: str) -> str:
    # Remove footnotes and cross-references
    text = re.sub(r"\\f\s+.*?\\f\*", "", text)
    text = re.sub(r"\\x\s+.*?\\x\*", "", text)

    # Replace \w word|... \w* (strong/morph inside) with just the word
    # Covers strong H/G and other attrs after '|'
    text = re.sub(r"\\w\s+([^|\\]+)\|[^\\]*?\\w\*", r"\1", text)

    # If quedan fragmentos tipo palabra|strong="H####"
    text = re.sub(r"([^\s|]+)\|strong=\"[^\"]+\"", r"\1", text)
    text = re.sub(r"([^\s|]+)\|strong='[^']+'", r"\1", text)
    text = re.sub(r"([^\s|]+)\|lemma=\"[^\"]+\"", r"\1", text)
    text = re.sub(r"([^\s|]+)\|x-morph=\"[^\"]+\"", r"\1", text)
    text = re.sub(r"([^\s|]+)\|x-[a-zA-Z0-9_-]+=\"[^\"]+\"", r"\1", text)

    # Remove stray attributes with or without pipes
    text = re.sub(r"\s*\|?\s*strong=\"[^\"]+\"", "", text)
    text = re.sub(r"\s*\|?\s*strong='[^']+'", "", text)
    text = re.sub(r"\s*\|?\s*lemma=\"[^\"]+\"", "", text)
    text = re.sub(r"\s*\|?\s*x-morph=\"[^\"]+\"", "", text)
    text = re.sub(r"\s*\|?\s*x-[a-zA-Z0-9_-]+=\"[^\"]+\"", "", text)

    # Remove inline strong/lemma/morph if any slipped
    text = re.sub(r'\s*strong="[^"]+"', "", text)
    text = re.sub(r"\s*strong='[^']+'", "", text)
    text = re.sub(r'\s*lemma="[^"]+"', "", text)
    text = re.sub(r'\s*x-morph="[^"]+"', "", text)
    text = re.sub(r'\s*x-[a-zA-Z0-9_-]+="[^"]+"', "", text)
    text = re.sub(r'\s*strong=\S+', "", text)

    # Remove remaining USFM markers like \i, \b, \nd, \w, \w*
    text = re.sub(r"\\w\*", "", text)
    text = re.sub(r"\\w", "", text)
    text = re.sub(r"\\[a-zA-Z]+\*?", "", text)

    # Cleanup braces, pipes, extra spaces
    text = text.replace("{", "").replace("}", "")
    text = text.replace("|", " ")
    text = re.sub(r"\s{2,}", " ", text)
    return text.strip()


def ensure_output_dir():
    OUTPUT_DB.parent.mkdir(parents=True, exist_ok=True)
    if OUTPUT_DB.exists():
        OUTPUT_DB.unlink()


def create_schema(conn: sqlite3.Connection):
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book TEXT,
            chapter INTEGER,
            verse INTEGER,
            text TEXT,
            UNIQUE(book, chapter, verse)
        );
        """
    )
    cur.execute(
        """
        CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT
        );
        """
    )
    cur.execute(
        "INSERT OR REPLACE INTO meta(key,value) VALUES (?, ?);",
        ("source", "RV1909 Public Domain - eBible.org"),
    )
    conn.commit()


def parse_usfm(zip_path: Path):
    verses = []
    with zipfile.ZipFile(zip_path, "r") as zf:
        for name in sorted(zf.namelist()):
            if not name.lower().endswith(".usfm"):
                continue
            book_id = None
            chapter = None
            with zf.open(name, "r") as f:
                for raw_line in f:
                    line = raw_line.decode("utf-8", errors="ignore").strip()
                    if not line:
                        continue

                    m_id = USFM_ID_RE.match(line)
                    if m_id:
                        book_id = m_id.group(1)
                        continue

                    m_c = USFM_CHAPTER_RE.match(line)
                    if m_c:
                        chapter = int(m_c.group(1))
                        continue

                    m_v = USFM_VERSE_RE.match(line)
                    if m_v and book_id and chapter:
                        verse_num = int(m_v.group(1))
                        text = clean_text(m_v.group(2))
                        verses.append((book_id, chapter, verse_num, text))
    return verses


def insert_verses(conn: sqlite3.Connection, verses):
    cur = conn.cursor()
    cur.executemany(
        "INSERT OR IGNORE INTO verses(book, chapter, verse, text) VALUES (?,?,?,?)",
        verses,
    )
    conn.commit()
    return cur.rowcount


def main():
    if not INPUT_ZIP.exists():
        raise FileNotFoundError(f"No se encontró el ZIP: {INPUT_ZIP}")

    ensure_output_dir()
    conn = sqlite3.connect(str(OUTPUT_DB))
    create_schema(conn)

    verses = parse_usfm(INPUT_ZIP)
    inserted = insert_verses(conn, verses)
    # Self-check GEN 1:1
    try:
        cur = conn.cursor()
        row = cur.execute(
            "SELECT text FROM verses WHERE book = ? AND chapter = 1 AND verse = 1 LIMIT 1",
            ("GEN",),
        ).fetchone()
        sample = row[0] if row else ""
        if 'strong="' in sample or r"\w" in sample:
            print("ADVERTENCIA: GEN 1:1 aún contiene marcadores Strong/USFM:")
            print(sample)
        else:
            print("Self-check OK: GEN 1:1 sin marcadores Strong/USFM.")
    except Exception as e:
        print(f"Self-check falló: {e}")

    conn.close()
    print(f"Versículos insertados: {inserted}")
    print(f"DB generada en: {OUTPUT_DB}")


if __name__ == "__main__":
    main()

