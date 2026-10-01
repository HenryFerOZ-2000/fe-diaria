/// Fotografías incluidas en la app (Licencia Unsplash; créditos en
/// assets/licenses/unsplash_photos.txt).
enum VerbumPhotos {
  bibleHills,
  candle,
  clouds,
  coffeeBible,
  lake,
  morning,
  night,
  pathFlowers,
  prayingHands,
  rosary,
  sunset;

  String get asset {
    final snake = name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );
    return 'assets/images/photos/$snake.jpg';
  }
}
