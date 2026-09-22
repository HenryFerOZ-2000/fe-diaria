import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/sharing/application/share_export_coordinator.dart';
import 'package:verbum/features/sharing/data/share_platform_gateway.dart';
import 'package:verbum/features/sharing/domain/share_card_format.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';
import 'package:verbum/features/sharing/domain/share_visual_style.dart';
import 'package:verbum/features/sharing/presentation/share_composer_screen.dart';
import 'package:verbum/features/sharing/presentation/verbum_share_card.dart';

final _content = ShareContent(
  title: 'Una palabra de esperanza',
  body: 'El Señor es mi pastor; nada me falta.',
  reference: 'Salmo 23, 1',
  kind: ShareContentKind.psalm,
);
final _longContent = ShareContent(
  title: 'Una oración',
  body: List.filled(
    24,
    'Danos sabiduría, paz y valentía para amar sin medida.',
  ).join(' '),
  reference: 'Oración del día',
  kind: ShareContentKind.prayer,
);

class _UnusedGateway implements SharePlatformGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EffectGateway extends _UnusedGateway {
  int effects = 0;

  @override
  Future<Directory> temporaryDirectory() async {
    effects++;
    throw StateError('Rendering must finish before writing any files.');
  }

  @override
  Future<NativeShareStatus> shareFiles(List<String> paths, String text) async {
    effects++;
    return NativeShareStatus.success;
  }

  @override
  Future<void> saveImage(String path) async => effects++;
}

class _Coordinator extends ShareExportCoordinator {
  _Coordinator() : super(_UnusedGateway());
  Completer<ShareExportResult>? pending;
  ShareExportFailure? failure;
  bool capture = false;
  int shared = 0;
  int saved = 0;
  ShareContent? copied;
  List<Uint8List>? images;
  SharePageRenderer? renderer;

  Future<ShareExportResult> _export(SharePageRenderer renderPages) async {
    renderer = renderPages;
    if (failure case final error?) throw error;
    if (capture) images = await renderPages();
    return pending?.future ?? ShareExportResult.dismissed;
  }

  @override
  Future<ShareExportResult> share({
    required ShareContent content,
    required SharePageRenderer renderPages,
  }) {
    shared++;
    return _export(renderPages);
  }

  @override
  Future<ShareExportResult> save({
    required ShareContent content,
    required SharePageRenderer renderPages,
  }) {
    saved++;
    return _export(renderPages);
  }

  @override
  Future<void> copy(ShareContent content) async => copied = content;
}

Future<void> _pump(
  WidgetTester tester,
  _Coordinator coordinator, {
  ShareContent? content,
  Size size = const Size(390, 844),
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness, fontFamily: 'VerbumInter'),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: ShareComposerScreen(
          content: content ?? _content,
          coordinator: coordinator,
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/icon/icon.png'),
      tester.element(find.byType(VerbumShareCard)),
    ),
  );
  await tester.pumpAndSettle();
}

VerbumShareCard _card(WidgetTester tester) =>
    tester.widget(find.byType(VerbumShareCard));

void main() {
  setUpAll(() async {
    for (final entry in {
      'VerbumInter': 'assets/fonts/Inter-Variable.ttf',
      'VerbumPlayfair': 'assets/fonts/PlayfairDisplay-Variable.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  testWidgets('defaults to portrait and the content-resolved environment', (
    tester,
  ) async {
    await _pump(tester, _Coordinator());
    expect(_card(tester).format, ShareCardFormat.portrait);
    expect(_card(tester).style, ShareVisualStyle.livingTradition);
    expect(find.byKey(const Key('share-page-navigation')), findsNothing);
  });

  testWidgets('format selection repaginates and exposes selected semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _Coordinator(), content: _longContent);
    await tester.tap(find.text('1:1'));
    await tester.pumpAndSettle();
    final squareCount = _card(tester).page.total;
    expect(_card(tester).format, ShareCardFormat.square);
    expect(
      tester
          .getSemantics(find.byKey(const Key('share-format-square')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    await tester.tap(find.text('9:16'));
    await tester.pumpAndSettle();
    expect(_card(tester).format, ShareCardFormat.story);
    expect(_card(tester).page.total, lessThan(squareCount));
    semantics.dispose();
  });

  testWidgets(
    'swiping environments preserves spiritual content and reference',
    (tester) async {
      await _pump(tester, _Coordinator());
      await tester.drag(
        find.byKey(const Key('share-style-carousel')),
        const Offset(250, 0),
      );
      await tester.pumpAndSettle();
      expect(_card(tester).style, ShareVisualStyle.contemplativeNight);
      expect(_card(tester).page.body, _content.body);
      expect(_card(tester).content.reference, 'Salmo 23, 1');
    },
  );

  testWidgets('multiple pages have working previous and next controls', (
    tester,
  ) async {
    await _pump(tester, _Coordinator(), content: _longContent);
    expect(find.byKey(const Key('share-page-navigation')), findsOneWidget);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(_card(tester).page.index, 2);
    await tester.tap(find.byTooltip('Página anterior'));
    await tester.pumpAndSettle();
    expect(_card(tester).page.index, 1);
  });

  for (final action in ['Compartir', 'Guardar']) {
    testWidgets(
      '$action blocks duplicate work and dismissal removes progress',
      (tester) async {
        final coordinator = _Coordinator()
          ..pending = Completer<ShareExportResult>();
        await _pump(tester, coordinator);
        await tester.tap(find.byTooltip(action));
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(ShareComposerScreen),
            matching: find.byType(ModalBarrier),
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('share-primary-action')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<IconButton>(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is IconButton && widget.tooltip == 'Guardar',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<PopupMenuButton<String>>(
                find.byKey(const Key('share-more-actions')),
              )
              .enabled,
          isFalse,
        );
        coordinator.pending!.complete(ShareExportResult.dismissed);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(ShareComposerScreen),
            matching: find.byType(ModalBarrier),
          ),
          findsNothing,
        );
        expect(find.textContaining('No pudimos'), findsNothing);
        expect(coordinator.shared + coordinator.saved, 1);
      },
    );
  }

  testWidgets('typed failure offers retry for the failed operation', (
    tester,
  ) async {
    final coordinator = _Coordinator()
      ..failure = const ShareExportFailure.render();
    await _pump(tester, coordinator);
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos crear la tarjeta.'), findsOneWidget);
    coordinator.failure = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(coordinator.saved, 2);
    expect(coordinator.shared, 0);
  });

  testWidgets('copy delegates the content and confirms success', (
    tester,
  ) async {
    final coordinator = _Coordinator();
    await _pump(tester, coordinator);
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar texto y enlace'));
    await tester.pumpAndSettle();
    expect(coordinator.copied, _content);
    expect(find.text('Texto y enlace copiados'), findsOneWidget);
  });

  testWidgets('closing pops without exporting or copying', (tester) async {
    final coordinator = _Coordinator();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ShareComposerScreen(
                  content: _content,
                  coordinator: coordinator,
                ),
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(coordinator.shared + coordinator.saved, 0);
    expect(coordinator.copied, isNull);
  });

  testWidgets('320 by 568 at 200% remains accessible with the dock visible', (
    tester,
  ) async {
    await _pump(tester, _Coordinator(), size: const Size(320, 568), scale: 2);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Compartir').hitTestable(), findsOneWidget);
    final headingContext = tester.element(find.text('Comparte la Palabra'));
    expect(MediaQuery.textScalerOf(headingContext).scale(20), 40);
    await tester.ensureVisible(find.text('9:16'));
    await tester.tap(find.text('9:16'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark application theme preserves the selected export style', (
    tester,
  ) async {
    await _pump(tester, _Coordinator(), brightness: Brightness.dark);
    await tester.tap(find.byKey(const Key('share-style-sereneLight')));
    await tester.pumpAndSettle();
    expect(_card(tester).style, ShareVisualStyle.sereneLight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures every page in order and restores the selected page', (
    tester,
  ) async {
    final coordinator = _Coordinator()..capture = true;
    await _pump(tester, coordinator, content: _longContent);
    final count = _card(tester).page.total;
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Guardar'));
    final seen = <int>[];
    await tester.runAsync(() async {
      for (var frame = 0; frame < 200 && coordinator.images == null; frame++) {
        await tester.pump();
        final page = _card(tester).page.index;
        if (seen.isEmpty || seen.last != page) seen.add(page);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(coordinator.images, hasLength(count));
      expect(seen, List.generate(count, (index) => index + 1));
      for (final bytes in coordinator.images!) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 1080);
        expect(frame.image.height, 1350);
        frame.image.dispose();
        codec.dispose();
      }
    });
    await tester.pumpAndSettle();
    expect(_card(tester).page.index, 2);
  });

  testWidgets('a disposed multi-page render exports no partial set', (
    tester,
  ) async {
    final coordinator = _Coordinator();
    final content = ShareContent(
      title: 'Oración',
      body: List.filled(4, _longContent.body).join('\n\n'),
      kind: ShareContentKind.prayer,
    );
    await _pump(tester, coordinator, content: content);
    await tester.tap(find.byTooltip('Compartir'));
    await tester.pumpAndSettle();
    final gateway = _EffectGateway();
    final realCoordinator = ShareExportCoordinator(gateway);
    await tester.runAsync(() async {
      final future = realCoordinator.share(
        content: content,
        renderPages: coordinator.renderer!,
      );
      final assertion = expectLater(
        future,
        throwsA(
          isA<ShareExportFailure>().having(
            (error) => error.stage,
            'stage',
            ShareExportStage.render,
          ),
        ),
      );
      for (
        var frame = 0;
        frame < 100 && _card(tester).page.index < 2;
        frame++
      ) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(_card(tester).page.index, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await assertion;
    });
    expect(gateway.effects, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures after scrolling compact format controls into view', (
    tester,
  ) async {
    final coordinator = _Coordinator()..capture = true;
    await _pump(tester, coordinator, size: const Size(320, 568), scale: 2);
    await tester.ensureVisible(find.text('9:16'));
    await tester.tap(find.text('9:16'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Compartir'));
    await tester.runAsync(() async {
      for (var frame = 0; frame < 100 && coordinator.images == null; frame++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(coordinator.images, hasLength(1));
      final codec = await ui.instantiateImageCodec(coordinator.images!.single);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1080);
      expect(frame.image.height, 1920);
      frame.image.dispose();
      codec.dispose();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait export decodes to exactly 1080 by 1350', (
    tester,
  ) async {
    final coordinator = _Coordinator()..capture = true;
    await _pump(tester, coordinator);
    await tester.tap(find.byTooltip('Compartir'));
    await tester.runAsync(() async {
      for (var frame = 0; frame < 100 && coordinator.images == null; frame++) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(coordinator.images, hasLength(1));
      final codec = await ui.instantiateImageCodec(coordinator.images!.single);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1080);
      expect(frame.image.height, 1350);
      if (const bool.fromEnvironment('SHARE_DEBUG_CAPTURE')) {
        await File(
          'build/share_composer_portrait.png',
        ).writeAsBytes(coordinator.images!.single);
      }
      frame.image.dispose();
      codec.dispose();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
