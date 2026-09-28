import 'package:flutter/painting.dart';

import '../domain/share_card_format.dart';

/// Fixed output-space metrics shared by pagination, preview and PNG capture.
class ShareCardLayout {
  const ShareCardLayout(this.format);

  final ShareCardFormat format;

  Size get size => format.pixelSize;
  double get horizontalInset => format == ShareCardFormat.story ? 104 : 96;
  double get verticalInset => switch (format) {
    ShareCardFormat.square => 72,
    ShareCardFormat.portrait => 80,
    ShareCardFormat.story => 112,
  };
  double get logoRegionHeight => format == ShareCardFormat.story ? 128 : 112;
  double get referenceRegionHeight => format == ShareCardFormat.story ? 96 : 88;
  double get footerRegionHeight => format == ShareCardFormat.story ? 88 : 80;
  double get pageMarkerRegionHeight =>
      format == ShareCardFormat.story ? 72 : 64;

  TextStyle get bodyStyle => TextStyle(
    fontFamily: 'VerbumPlayfair',
    fontSize: switch (format) {
      ShareCardFormat.square => 42,
      ShareCardFormat.portrait => 40,
      ShareCardFormat.story => 38,
    },
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  Size bodyBox({required bool reservePageMarker}) => Size(
    size.width - horizontalInset * 2,
    size.height -
        verticalInset * 2 -
        logoRegionHeight -
        referenceRegionHeight -
        footerRegionHeight -
        (reservePageMarker ? pageMarkerRegionHeight : 0),
  );
}
