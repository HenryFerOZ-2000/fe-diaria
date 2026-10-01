import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/photos/verbum_photos.dart';

void main() {
  test('cada foto apunta a un archivo incluido', () {
    expect(
      VerbumPhotos.bibleHills.asset,
      'assets/images/photos/bible_hills.jpg',
    );
    for (final photo in VerbumPhotos.values) {
      expect(File(photo.asset).existsSync(), isTrue, reason: photo.asset);
    }
  });
}
