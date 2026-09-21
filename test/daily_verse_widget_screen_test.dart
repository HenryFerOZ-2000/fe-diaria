import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/l10n/app_localizations.dart';
import 'package:verbum/models/verse.dart';
import 'package:verbum/screens/daily_verse_widget_screen.dart';
import 'package:verbum/services/widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ozcorp.verbum/widget-screen-test');
  final spanish = AppLocalizations('es');

  Future<Verse> loadVerse() async => Verse(
    id: 20260921,
    text: 'Jehová es mi pastor; nada me faltará.',
    reference: 'Salmos 23:1',
    book: 'PSA',
    chapter: 23,
    verse: 1,
  );

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets('muestra la vista previa y solicita añadir a inicio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'hasWidgets') return false;
          if (call.method == 'isPinWidgetSupported') return true;
          if (call.method == 'requestPinWidget') return true;
          return false;
        });
    final service = WidgetService.forTesting(channel: channel, isAndroid: true);

    await tester.pumpWidget(
      MaterialApp(
        home: DailyVerseWidgetScreen(
          widgetService: service,
          loadVerse: loadVerse,
          localizations: spanish,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Widget de la Palabra'), findsOneWidget);
    expect(find.text('Salmos 23:1'), findsOneWidget);
    await tester.tap(find.text('Añadir a inicio'));
    await tester.pumpAndSettle();
    expect(find.textContaining('solicitud enviada'), findsOneWidget);
  });

  testWidgets(
    'explica instalación manual cuando el launcher no soporta fijación',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'hasWidgets') return false;
            if (call.method == 'isPinWidgetSupported') return false;
            return false;
          });
      final service = WidgetService.forTesting(
        channel: channel,
        isAndroid: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DailyVerseWidgetScreen(
            widgetService: service,
            loadVerse: loadVerse,
            localizations: spanish,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir a inicio'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Mantén pulsada la pantalla de inicio'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra el estado añadido cuando Android informa una instancia',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'hasWidgets') return true;
            return false;
          });
      final service = WidgetService.forTesting(
        channel: channel,
        isAndroid: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DailyVerseWidgetScreen(
            widgetService: service,
            loadVerse: loadVerse,
            localizations: spanish,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Widget añadido'), findsOneWidget);
    },
  );

  testWidgets('no desborda a 320 px con texto al 200 por ciento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);
    final service = WidgetService.forTesting(channel: channel, isAndroid: true);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          home: DailyVerseWidgetScreen(
            widgetService: service,
            loadVerse: loadVerse,
            localizations: spanish,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
