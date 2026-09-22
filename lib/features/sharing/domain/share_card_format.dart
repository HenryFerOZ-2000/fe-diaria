import 'dart:ui';

enum ShareCardFormat { square, portrait, story }

extension ShareCardFormatGeometry on ShareCardFormat {
  Size get pixelSize => switch (this) {
    ShareCardFormat.square => const Size(1080, 1080),
    ShareCardFormat.portrait => const Size(1080, 1350),
    ShareCardFormat.story => const Size(1080, 1920),
  };

  String get label => switch (this) {
    ShareCardFormat.square => '1:1',
    ShareCardFormat.portrait => '4:5',
    ShareCardFormat.story => '9:16',
  };
}
