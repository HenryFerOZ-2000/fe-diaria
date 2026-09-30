import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  test('cada icono del catálogo tiene sus tres pesos en assets', () {
    final missing = [
      for (final icon in VerbumIcons.values)
        for (final weight in VIconWeight.values)
          if (!File(VIcon.assetPath(icon, weight)).existsSync())
            VIcon.assetPath(icon, weight),
    ];
    expect(missing, isEmpty);
  });
}
