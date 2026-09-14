enum BibleTestament { old, newTestament }

class BibleBookInfo {
  final String id;
  final String name;
  final String section;
  final BibleTestament testament;

  const BibleBookInfo({
    required this.id,
    required this.name,
    required this.section,
    required this.testament,
  });
}

const bibleBooks = <BibleBookInfo>[
  BibleBookInfo(
    id: 'GEN',
    name: 'Génesis',
    section: 'Pentateuco',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'EXO',
    name: 'Éxodo',
    section: 'Pentateuco',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'LEV',
    name: 'Levítico',
    section: 'Pentateuco',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'NUM',
    name: 'Números',
    section: 'Pentateuco',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'DEU',
    name: 'Deuteronomio',
    section: 'Pentateuco',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'JOS',
    name: 'Josué',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'JDG',
    name: 'Jueces',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'RUT',
    name: 'Rut',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: '1SA',
    name: '1 Samuel',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: '2SA',
    name: '2 Samuel',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: '1KI',
    name: '1 Reyes',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: '2KI',
    name: '2 Reyes',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: '1CH',
    name: '1 Crónicas',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: '2CH',
    name: '2 Crónicas',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'EZR',
    name: 'Esdras',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'NEH',
    name: 'Nehemías',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'EST',
    name: 'Ester',
    section: 'Libros históricos',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'JOB',
    name: 'Job',
    section: 'Poéticos y sapienciales',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'PSA',
    name: 'Salmos',
    section: 'Poéticos y sapienciales',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'PRO',
    name: 'Proverbios',
    section: 'Poéticos y sapienciales',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'ECC',
    name: 'Eclesiastés',
    section: 'Poéticos y sapienciales',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'SNG',
    name: 'Cantares',
    section: 'Poéticos y sapienciales',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'ISA',
    name: 'Isaías',
    section: 'Profetas mayores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'JER',
    name: 'Jeremías',
    section: 'Profetas mayores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'LAM',
    name: 'Lamentaciones',
    section: 'Profetas mayores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'EZK',
    name: 'Ezequiel',
    section: 'Profetas mayores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'DAN',
    name: 'Daniel',
    section: 'Profetas mayores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'HOS',
    name: 'Oseas',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'JOL',
    name: 'Joel',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'AMO',
    name: 'Amós',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'OBA',
    name: 'Abdías',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'JON',
    name: 'Jonás',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'MIC',
    name: 'Miqueas',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'NAM',
    name: 'Nahúm',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'HAB',
    name: 'Habacuc',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'ZEP',
    name: 'Sofonías',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'HAG',
    name: 'Hageo',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'ZEC',
    name: 'Zacarías',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'MAL',
    name: 'Malaquías',
    section: 'Profetas menores',
    testament: BibleTestament.old,
  ),
  BibleBookInfo(
    id: 'MAT',
    name: 'Mateo',
    section: 'Evangelios',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'MRK',
    name: 'Marcos',
    section: 'Evangelios',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'LUK',
    name: 'Lucas',
    section: 'Evangelios',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'JHN',
    name: 'Juan',
    section: 'Evangelios',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'ACT',
    name: 'Hechos',
    section: 'Historia de la Iglesia',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'ROM',
    name: 'Romanos',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '1CO',
    name: '1 Corintios',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '2CO',
    name: '2 Corintios',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'GAL',
    name: 'Gálatas',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'EPH',
    name: 'Efesios',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'PHP',
    name: 'Filipenses',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'COL',
    name: 'Colosenses',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '1TH',
    name: '1 Tesalonicenses',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '2TH',
    name: '2 Tesalonicenses',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '1TI',
    name: '1 Timoteo',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '2TI',
    name: '2 Timoteo',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'TIT',
    name: 'Tito',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'PHM',
    name: 'Filemón',
    section: 'Cartas de Pablo',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'HEB',
    name: 'Hebreos',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'JAS',
    name: 'Santiago',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '1PE',
    name: '1 Pedro',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '2PE',
    name: '2 Pedro',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '1JN',
    name: '1 Juan',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '2JN',
    name: '2 Juan',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: '3JN',
    name: '3 Juan',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'JUD',
    name: 'Judas',
    section: 'Cartas generales',
    testament: BibleTestament.newTestament,
  ),
  BibleBookInfo(
    id: 'REV',
    name: 'Apocalipsis',
    section: 'Profecía',
    testament: BibleTestament.newTestament,
  ),
];

BibleBookInfo? bibleBookById(String id) {
  for (final book in bibleBooks) {
    if (book.id == id) return book;
  }
  return null;
}
