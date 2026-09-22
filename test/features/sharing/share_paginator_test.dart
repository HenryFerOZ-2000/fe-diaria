import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/sharing/application/share_paginator.dart';
import 'package:verbum/features/sharing/domain/share_card_format.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';

void main() {
  late SharePaginator paginator;

  setUp(() {
    paginator = const SharePaginator();
  });

  test('keeps a short verse on one numbered page', () {
    final verse = ShareContent(
      title: 'Versículo del día',
      body: '«Todo lo puedo en Cristo que me fortalece.»',
      kind: ShareContentKind.verse,
      reference: 'Filipenses 4:13',
    );

    final pages = paginator.paginate(verse, format: ShareCardFormat.portrait);

    expect(pages, hasLength(1));
    expect(pages.single.body, verse.body);
    expect(pages.single.index, 1);
    expect(pages.single.total, 1);
  });

  test('paginates a long prayer without losing content or numbering', () {
    final longPrayer = ShareContent(
      title: 'Oración de confianza',
      body: List<String>.generate(
        36,
        (index) =>
            'Señor, acompáñanos en el camino ${index + 1}. '
            'Danos sabiduría, paz y valentía para amar sin medida. '
            '«Tu gracia nos basta», hoy y siempre.',
      ).join('\n\n'),
      kind: ShareContentKind.prayer,
    );

    final pages = paginator.paginate(
      longPrayer,
      format: ShareCardFormat.portrait,
    );

    expect(pages.length, greaterThan(1));
    expect(
      pages.map((page) => page.index),
      orderedEquals(List<int>.generate(pages.length, (index) => index + 1)),
    );
    expect(pages.every((page) => page.total == pages.length), isTrue);
    expect(pages.map((page) => page.body).join(), longPrayer.body.trim());
    expect(pages.every((page) => page.body.trim().isNotEmpty), isTrue);
  });

  test('normalizes CRLF only and preserves blank-line separators verbatim', () {
    final prayer = ShareContent(
      title: 'Oración con pausas',
      body:
          ' \r\n  Padre bueno: escucha nuestra oración.\r\n\r\n\r\n'
          '  «Quédate con nosotros», Señor.  \r\n\r\n'
          'Amén; confiamos en ti. \r\n ',
      kind: ShareContentKind.prayer,
    );
    const expected =
        'Padre bueno: escucha nuestra oración.\n\n\n'
        '  «Quédate con nosotros», Señor.  \n\n'
        'Amén; confiamos en ti.';

    for (final format in ShareCardFormat.values) {
      final pages = paginator.paginate(prayer, format: format);

      expect(
        pages.map((page) => page.body).join(),
        expected,
        reason: 'failed to reconstruct $format',
      );
      expect(pages.every((page) => page.body.trim().isNotEmpty), isTrue);
    }
  });

  test('preserves a 120-character unbroken token on its own page', () {
    final token = List.filled(120, 'á').join();
    final prayer = ShareContent(
      title: 'Oración continua',
      body: 'Antes del silencio.\n\n$token\n\nDespués del silencio.',
      kind: ShareContentKind.prayer,
    );

    final pages = paginator.paginate(prayer, format: ShareCardFormat.square);

    expect(pages.map((page) => page.body).join(), prayer.body);
    expect(pages.where((page) => page.body.trim() == token), hasLength(1));
  });

  test('includes a trailing paragraph separator in fit measurement', () {
    final firstParagraph = List<String>.generate(
      10,
      (index) => 'Línea ${index + 1}.',
    ).join('\n');
    final prayer = ShareContent(
      title: 'Oración al límite',
      body: '$firstParagraph\n\nCierre.',
      kind: ShareContentKind.prayer,
    );

    final pages = paginator.paginate(prayer, format: ShareCardFormat.square);

    expect(pages, hasLength(2));
    expect(pages.first.body, isNot('$firstParagraph\n\n'));
    expect(pages.last.body, startsWith('Línea 10.\n\n'));
    expect(pages.map((page) => page.body).join(), prayer.body);
  });

  test('accepts right-to-left measurement without changing stored text', () {
    final reflection = ShareContent(
      title: 'Reflexión',
      body: List.filled(
        18,
        'La paz comienza cuando escuchamos con el corazón.',
      ).join(' '),
      kind: ShareContentKind.reflection,
    );

    final pages = paginator.paginate(
      reflection,
      format: ShareCardFormat.story,
      textDirection: TextDirection.rtl,
    );

    expect(pages.map((page) => page.body).join(), reflection.body);
    expect(pages.every((page) => page.body.trim().isNotEmpty), isTrue);
  });

  test('square needs more pages than portrait for oversized content', () {
    final oversizedPrayer = ShareContent(
      title: 'Oración extensa',
      body: List<String>.generate(
        45,
        (index) =>
            'Petición ${index + 1}: ilumina nuestros pasos y enséñanos '
            'a servir con alegría, paciencia y compasión.',
      ).join('\n\n'),
      kind: ShareContentKind.prayer,
    );

    final squarePages = paginator.paginate(
      oversizedPrayer,
      format: ShareCardFormat.square,
    );
    final portraitPages = paginator.paginate(
      oversizedPrayer,
      format: ShareCardFormat.portrait,
    );

    expect(squarePages.length, greaterThan(portraitPages.length));
    expect(squarePages.map((page) => page.body).join(), oversizedPrayer.body);
    expect(portraitPages.map((page) => page.body).join(), oversizedPrayer.body);
  });
}
