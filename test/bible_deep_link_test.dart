import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/services/bible_deep_link.dart';

void main() {
  test('analiza un enlace bíblico exacto', () {
    expect(
      parseBibleDeepLink(Uri.parse('verbum://biblia/JHN/3/16')),
      const BibleDeepLinkTarget(bookId: 'JHN', chapter: 3, verse: 16),
    );
  });

  test('rechaza host, libro o números inválidos', () {
    expect(parseBibleDeepLink(Uri.parse('verbum://camino/JHN/3/16')), isNull);
    expect(
      parseBibleDeepLink(Uri.parse('verbum://biblia/UNKNOWN/3/16')),
      isNull,
    );
    expect(parseBibleDeepLink(Uri.parse('verbum://biblia/JHN/0/16')), isNull);
    expect(parseBibleDeepLink(Uri.parse('verbum://biblia/JHN/3/x')), isNull);
  });

  test('serializa con el mismo contrato del PendingIntent', () {
    const target = BibleDeepLinkTarget(bookId: 'PSA', chapter: 23, verse: 1);

    expect(target.toUri().toString(), 'verbum://biblia/PSA/23/1');
  });
}
