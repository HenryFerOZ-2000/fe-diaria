import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/novena/presentation/novena_themes.dart';

void main() {
  test('cada día tiene su propia temática, icono y foto', () {
    final days = [for (var d = 1; d <= 9; d++) novenaThemeFor(d)];
    expect(days.map((t) => t.name).toSet(), hasLength(9));
    expect(days.map((t) => t.icon).toSet(), hasLength(9));
    expect(days.map((t) => t.photo).toSet(), hasLength(9));
    expect(novenaThemeFor(3).name, 'La paz');
    expect(novenaThemeFor(0), novenaThemeFor(1));
  });
}
