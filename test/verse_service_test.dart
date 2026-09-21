import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/services/verse_service.dart';

void main() {
  test(
    'la referencia diaria muestra el nombre bíblico y no el código interno',
    () {
      expect(formatBibleReference('PSA', 23, 1), 'Salmos 23:1');
      expect(formatBibleReference('JHN', 3, 16), 'Juan 3:16');
    },
  );
}
