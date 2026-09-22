import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/sharing/application/share_paginator.dart';
import 'package:verbum/features/sharing/domain/share_card_format.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';
import 'package:verbum/features/sharing/domain/share_page.dart';
import 'package:verbum/features/sharing/domain/share_visual_style.dart';
import 'package:verbum/features/sharing/presentation/verbum_share_card.dart';

const _body = '«El Señor es mi pastor; nada me falta.»';
final _content = ShareContent(
  title: 'Una palabra de esperanza',
  body: _body,
  kind: ShareContentKind.psalm,
  reference: 'Salmo 23, 1',
  sourceLabel: 'https://example.com/internal-only',
  shareCaption: 'https://apps.apple.com/internal-only',
);
const _page = SharePage(body: _body, index: 2, total: 3);

Future<void> _pumpCard(
  WidgetTester tester, {
  ShareCardFormat format = ShareCardFormat.portrait,
  ShareVisualStyle style = ShareVisualStyle.sereneLight,
  ShareContent? content,
  SharePage page = _page,
  double width = 540,
  double textScale = 1,
}) async {
  final size = Size(width, width / format.pixelSize.aspectRatio);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Center(
          child: SizedBox.fromSize(
            size: size,
            child: RepaintBoundary(
              key: const Key('card-capture'),
              child: VerbumShareCard(
                content: content ?? _content,
                page: page,
                format: format,
                style: style,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/icon/icon.png'),
      tester.element(find.byType(VerbumShareCard)),
    );
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final font in {
      'VerbumInter': 'assets/fonts/Inter-Variable.ttf',
      'VerbumPlayfair': 'assets/fonts/PlayfairDisplay-Variable.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  testWidgets('exposes logo, spiritual copy, reference and page semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester);

    expect(find.byKey(const Key('share-card-logo')), findsOneWidget);
    expect(find.byKey(const Key('share-card-body')), findsOneWidget);
    expect(find.text('Salmo 23, 1'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Logotipo de Verbum'), findsOneWidget);
    expect(find.bySemanticsLabel(_body), findsOneWidget);
    expect(find.bySemanticsLabel('Salmo 23, 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Página 2 de 3'), findsOneWidget);
    expect(find.textContaining('apps.apple.com'), findsNothing);
    expect(find.textContaining('https://'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('trims only displayed separators and omits single-page count', (
    tester,
  ) async {
    const page = SharePage(body: ' \n$_body\n\n', index: 1, total: 1);
    await _pumpCard(tester, page: page);

    expect(find.text(_body), findsOneWidget);
    expect(page.body, ' \n$_body\n\n');
    expect(find.text('1 de 1'), findsNothing);
  });

  testWidgets('renders its local assets with network disabled', (tester) async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = _NoNetwork();
    addTearDown(() => HttpOverrides.global = previous);
    await _pumpCard(tester);
    final image = tester.widget<Image>(
      find.byKey(const Key('share-card-logo')),
    );
    expect(image.image, isA<AssetImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('dense paginated copy fits every format at narrow preview size', (
    tester,
  ) async {
    final content = ShareContent(
      title: 'Oración de confianza',
      body: List.filled(
        18,
        'Señor, acompáñanos en el camino. Danos sabiduría, paz y valentía '
        'para amar sin medida. «Tu gracia nos basta», hoy y siempre.',
      ).join('\n\n'),
      kind: ShareContentKind.prayer,
    );
    for (final format in ShareCardFormat.values) {
      final pages = const SharePaginator().paginate(content, format: format);
      for (final page in pages) {
        await _pumpCard(
          tester,
          format: format,
          content: content,
          page: page,
          width: 280,
          textScale: 2.5,
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.byKey(const Key('share-card-body')),
        );
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.size.width);
        expect(painter.height, lessThanOrEqualTo(paragraph.size.height));
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(find.text(page.body.trim()), findsOneWidget);
        expect(tester.takeException(), isNull);
        painter.dispose();
      }
    }
  });

  for (final fixture in [
    (ShareCardFormat.portrait, ShareVisualStyle.sereneLight, 'light_4x5'),
    (ShareCardFormat.story, ShareVisualStyle.contemplativeNight, 'night_story'),
    (
      ShareCardFormat.square,
      ShareVisualStyle.livingTradition,
      'tradition_square',
    ),
  ]) {
    testWidgets('golden ${fixture.$3}', (tester) async {
      await _pumpCard(tester, format: fixture.$1, style: fixture.$2);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('card-capture')),
        matchesGoldenFile('goldens/share_card_${fixture.$3}.png'),
      );
    });
  }
}

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('Share cards must render without a network connection.');
  }
}
