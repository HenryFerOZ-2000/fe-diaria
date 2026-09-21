import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:verbum/screens/traditional_prayer_detail_screen.dart';
import 'package:verbum/screens/traditional_prayers_categories_screen.dart';
import 'package:verbum/screens/traditional_prayers_list_screen.dart';
import 'package:verbum/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'verbum_traditional_prayers_test_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox('favorites');
    await Hive.openBox('settings');
  });

  setUp(() async {
    final settings = Hive.box('settings');
    await settings.clear();
    await settings.put('adsRemoved', true);
    await settings.put('traditionalPrayersReligion', 'cristiana');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('oraciones bíblicas usa la experiencia editorial de Verbum', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const TraditionalPrayersListScreen(
          religion: 'cristiana',
          category: 'biblicas',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ORA CON LA PALABRA'), findsOneWidget);
    expect(find.text('Regresar al inicio'), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.text('Padre Nuestro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categorías tradicionales ya no conserva el diseño heredado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const TraditionalPrayersCategoriesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TU BIBLIOTECA DE ORACIÓN'), findsOneWidget);
    expect(find.text('Regresar al inicio'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el lector muestra el nombre visible de la categoría', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const TraditionalPrayerDetailScreen(
          religion: 'cristiana',
          category: 'otras',
          prayerKey: 'Oración de Entrega',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OTRAS ORACIONES'), findsOneWidget);
    expect(find.text('OTRAS'), findsNothing);
  });
}
