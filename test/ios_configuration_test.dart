import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS declares the photo permissions required by gallery export', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('<key>NSPhotoLibraryAddUsageDescription</key>'));
    expect(infoPlist, contains('<key>NSPhotoLibraryUsageDescription</key>'));
  });
}
