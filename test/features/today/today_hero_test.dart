import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/controllers/missions_controller.dart';
import 'package:verbum/design_system/design_system.dart';
import 'package:verbum/features/today/presentation/today_hero.dart';

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
    WidgetTester tester, {
    required List<Mission> list,
    DateTime? now,
    void Function(Mission)? onOpen,
    double textScale = 1,
    Size size = const Size(390, 844),
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: TodayHero(
                now: now ?? DateTime(2026, 9, 30, 12),
                missions: list,
                streakDays: 3,
                verseText: 'Mas en su voluntad está la vida.',
                onOpen: onOpen ?? (_) {},
                onProfile: () {},
                onStreak: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra fecha, racha y la Palabra de hoy', (tester) async {
    await pump(tester, list: missions());

    expect(find.text('Tu camino de hoy'), findsOneWidget);
    expect(find.text('MIÉRCOLES 30 SEP'), findsOneWidget);
    expect(find.text('3 días'), findsOneWidget);
    expect(find.textContaining('Mas en su voluntad'), findsOneWidget);
  });

  testWidgets('centra el siguiente momento pendiente y lo abre', (
    tester,
  ) async {
    Mission? opened;
    final list = missions()..first.completed = true;
    await pump(tester, list: list, onOpen: (m) => opened = m);

    // La carta central es la de mayor elevación.
    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    expect(opened?.id, 'morning');
  });

  testWidgets('todo completo cambia el título y la noche sigue bloqueada', (
    tester,
  ) async {
    Mission? opened;
    final list = missions();
    for (final m in list.where((m) => !m.isOptional)) {
      m.completed = true;
    }
    await pump(tester, list: list, onOpen: (m) => opened = m);

    expect(find.text('Camino de hoy completo'), findsOneWidget);
    expect(find.text('Desde las 19:00'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    expect(opened, isNull, reason: 'la noche no abre antes de las 19:00');
  });

  testWidgets('resiste 320 px y texto al 200 %', (tester) async {
    await pump(
      tester,
      list: missions(),
      textScale: 2,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
  });
}
