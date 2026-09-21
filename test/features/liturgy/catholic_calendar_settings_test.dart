import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';
import 'package:verbum/features/liturgy/presentation/catholic_calendar_settings_tile.dart';
import 'package:verbum/services/storage_service.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'verbum_liturgy_test_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox('settings');
  });

  setUp(() async {
    await Hive.box('settings').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('no muestra calendario católico a tradición evangélica', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatholicCalendarSettingsTile(
            tradition: FaithTradition.evangelical,
            selection: const CalendarSelection.generalRoman(),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Calendario católico'), findsNothing);
  });

  testWidgets('Ecuador explica el fallback y permite elegir General', (
    tester,
  ) async {
    CalendarSelection? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatholicCalendarSettingsTile(
            tradition: FaithTradition.catholic,
            selection: CalendarSelection.country('EC'),
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    expect(find.text('Ecuador · recomendado para ti'), findsOneWidget);
    expect(
      find.textContaining('se usa el Calendario Romano General'),
      findsOneWidget,
    );
    await tester.tap(find.text('Calendario católico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendario Romano General').last);
    await tester.pumpAndSettle();
    expect(changed, const CalendarSelection.generalRoman());
  });

  testWidgets('la fila resiste 320 px y texto al 200 %', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: CatholicCalendarSettingsTile(
                tradition: FaithTradition.catholic,
                selection: CalendarSelection.country('EC'),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('guardar calendario notifica a Hoy una vez', () async {
    final storage = StorageService();
    var notifications = 0;
    final listenable = storage.faithPreferencesListenable();
    void listener() => notifications++;
    listenable.addListener(listener);
    addTearDown(() => listenable.removeListener(listener));

    await storage.setCatholicCalendarSelection(CalendarSelection.country('EC'));
    expect(notifications, 1);
    expect(storage.getCatholicCalendarCountry(), 'EC');
  });
}
