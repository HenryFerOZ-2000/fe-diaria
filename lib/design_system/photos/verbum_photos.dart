/// Fotografías incluidas en la app (Licencia Unsplash; créditos en
/// assets/licenses/unsplash_photos.txt).
enum VerbumPhotos {
  bibleHills,
  candle,
  clouds,
  coffeeBible,
  elderReading,
  handsOnBible,
  handsTogether,
  journaling,
  lake,
  marianWindow,
  morning,
  night,
  pathFlowers,
  prayingHands,
  rosary,
  stainedGlass,
  sunrisePrayer,
  sunset,
  windowReading;

  String get asset {
    final snake = name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );
    return 'assets/images/photos/$snake.jpg';
  }
}
