# RV1909 SQLite Builder

Genera la base de datos SQLite offline para la Biblia Reina-Valera 1909 (dominio público) a partir del ZIP USFM.

## Requisitos
- Python 3.8+
- Paquetes estándar (zipfile, sqlite3, pathlib, re)

## Archivo de entrada
- `tools/bible_import/input/spaRV1909_usfm.zip`

## Salida
- `assets/db/rv1909.sqlite`

## Comando
```bash
python tools/bible_import/build_rv1909_sqlite.py
```

Al finalizar mostrará cuántos versículos se insertaron.

