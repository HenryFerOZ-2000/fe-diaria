class PrayerPassage {
  final String book;
  final int chapter;
  final int first;
  final int last;
  final String reference;
  const PrayerPassage(
    this.book,
    this.chapter,
    this.first,
    this.last,
    this.reference,
  );
}

List<PrayerPassage> biblicalPrayerPassages(String tradition, String key) {
  if (tradition != 'cristiana' && tradition != 'general') return const [];
  return switch (key) {
    'Padre Nuestro' => const [PrayerPassage('MAT', 6, 9, 13, 'Mateo 6:9–13')],
    'Salmo 23' => const [PrayerPassage('PSA', 23, 1, 6, 'Salmo 23:1–6')],
    'Salmo 91' => const [PrayerPassage('PSA', 91, 1, 16, 'Salmo 91:1–16')],
    'Promesas de Protección' => const [
      PrayerPassage('PSA', 34, 7, 7, 'Salmo 34:7'),
      PrayerPassage('ISA', 41, 10, 10, 'Isaías 41:10'),
      PrayerPassage('PSA', 4, 8, 8, 'Salmo 4:8'),
    ],
    'Promesas de Provisión' => const [
      PrayerPassage('PHP', 4, 19, 19, 'Filipenses 4:19'),
      PrayerPassage('MAT', 6, 33, 33, 'Mateo 6:33'),
      PrayerPassage('1CO', 10, 13, 13, '1 Corintios 10:13'),
    ],
    _ => const [],
  };
}
