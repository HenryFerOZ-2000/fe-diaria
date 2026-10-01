import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/controllers/missions_controller.dart';
import 'package:verbum/design_system/design_system.dart';
import 'package:verbum/features/today/presentation/today_cover.dart';
import 'package:verbum/features/today/presentation/today_journey.dart';

void main() {
  List<Mission> missions() => [
    Mission(
      id: 'verse',
      title: 'Recibe la Palabra',
      description: '',
      icon: VerbumIcons.book,
    ),
    Mission(
      id: 'morning',
      title: 'Ángelus',
      description: '',
      icon: VerbumIcons.sun,
    ),
    Mission(
      id: 'practice',
      title: 'Ora por alguien',
      description: '',
      icon: VerbumIcons.heart,
    ),
    Mission(
      id: 'night',
      title: 'Completas',
      description: '',
      icon: VerbumIcons.moon,
      isOptional: true,
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: buildVerbumTheme(brightness: Brightness.light),
          home: Scaffold(body: ListView(children: [child])),
        ),
      ),
    );
    await tester.pump();
  }

  TodayCover cover({VoidCallback? onRead, VoidCallback? onShare}) => TodayCover(
    now: DateTime(2026, 9, 30, 9),
    photo: VerbumPhotos.coverMountains,
    userName: 'Ana López',
    streakDays: 3,
    verseText: 'Lámpara es a mis pies tu palabra, y lumbrera a mi camino.',
    verseReference: 'Salmos 119:105',
    onRead: onRead ?? () {},
    onShare: onShare ?? () {},
    onProfile: () {},
    onStreak: () {},
  );

  testWidgets('la portada presenta el día con la Palabra', (tester) async {
    var read = false;
    var shared = false;
    await pump(
      tester,
      cover(onRead: () => read = true, onShare: () => shared = true),
    );

    expect(find.text('MIÉRCOLES 30 SEP'), findsOneWidget);
    expect(find.textContaining('lumbrera a mi camino'), findsOneWidget);
    expect(find.text('3 días'), findsOneWidget);
    await tester.tap(find.text('Leer y meditar'));
    await tester.tap(find.text('Compartir'));
    expect(read && shared, isTrue);
  });

  testWidgets('el siguiente paso es el primer momento pendiente', (
    tester,
  ) async {
    Mission? opened;
    final list = missions()..first.completed = true;
    await pump(
      tester,
      TodayJourney(
        missions: list,
        nightAvailable: false,
        onOpen: (m) => opened = m,
      ),
    );

    expect(find.text('TU SIGUIENTE PASO'), findsOneWidget);
    await tester.tap(find.text('Ángelus'));
    expect(opened?.id, 'morning');
    final tiles = tester.widgetList<VStepTile>(find.byType(VStepTile));
    expect(tiles.map((t) => t.state), [
      VStepState.done,
      VStepState.current,
      VStepState.upcoming,
      VStepState.upcoming,
    ]);
  });

  testWidgets(
    'con lo esencial hecho invita a la noche, bloqueada antes de hora',
    (tester) async {
      Mission? opened;
      final list = missions();
      for (final m in list.where((m) => !m.isOptional)) {
        m.completed = true;
      }
      await pump(
        tester,
        TodayJourney(
          missions: list,
          nightAvailable: false,
          onOpen: (m) => opened = m,
        ),
      );

      expect(find.text('PARA CERRAR EL DÍA'), findsOneWidget);
      expect(find.text('Disponible desde las 19:00'), findsOneWidget);
      await tester.tap(find.text('Completas'));
      expect(opened, isNull);
    },
  );

  testWidgets('resiste 320 px y texto al 200 %', (tester) async {
    await pump(
      tester,
      Column(
        children: [
          cover(),
          TodayJourney(
            missions: missions(),
            nightAvailable: true,
            onOpen: (_) {},
          ),
        ],
      ),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
