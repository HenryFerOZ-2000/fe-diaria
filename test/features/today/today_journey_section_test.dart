import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/controllers/missions_controller.dart';
import 'package:verbum/design_system/design_system.dart';
import 'package:verbum/features/today/presentation/today_journey_section.dart';

void main() {
  List<Mission> missions() => [
    Mission(
      id: 'verse',
      title: 'Recibe la Palabra',
      description: 'Lee',
      icon: VerbumIcons.book,
    ),
    Mission(
      id: 'morning',
      title: 'Hazla oración',
      description: 'Ora',
      icon: VerbumIcons.sun,
    ),
    Mission(
      id: 'practice',
      title: 'Ora por alguien',
      description: 'Pide',
      icon: VerbumIcons.heart,
    ),
  ];
  final night = Mission(
    id: 'night',
    title: 'Cierra tu día con Dios',
    description: 'Descansa en su paz',
    icon: VerbumIcons.moon,
    isOptional: true,
  );

  Future<List<Mission>> pump(
    WidgetTester tester, {
    required List<Mission> essentials,
    bool nightAvailable = false,
    void Function(Mission)? onOpen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerbumTheme(brightness: Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodayJourneySection(
              essentials: essentials,
              nextMission: essentials.where((m) => !m.completed).firstOrNull,
              optionalMission: night,
              nightAvailable: nightAvailable,
              verseText:
                  'Nadie que pone la mano en el arado y mira hacia atrás.',
              verseReference: 'Lucas 9, 62',
              onOpen: onOpen ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return essentials;
  }

  testWidgets('con la Palabra pendiente muestra el versículo con capitular', (
    tester,
  ) async {
    await pump(tester, essentials: missions());

    expect(find.text('PALABRA DEL DÍA'), findsOneWidget);
    expect(find.byType(VDropCapText), findsOneWidget);
    expect(find.text('Lucas 9, 62'), findsOneWidget);
    expect(find.text('0 de 3'), findsOneWidget);
  });

  testWidgets('marca los pasos hechos y el siguiente', (tester) async {
    final list = missions()..first.completed = true;
    await pump(tester, essentials: list);

    final tiles = tester.widgetList<VStepTile>(find.byType(VStepTile)).toList();
    expect(tiles.map((t) => t.state), [
      VStepState.done,
      VStepState.current,
      VStepState.upcoming,
    ]);
    expect(find.text('TU SIGUIENTE PASO'), findsOneWidget);
    expect(find.text('Hazla oración'), findsOneWidget);
  });

  testWidgets('todo completo muestra el cierre y la noche bloqueada', (
    tester,
  ) async {
    Mission? opened;
    final list = missions();
    for (final m in list) {
      m.completed = true;
    }
    await pump(tester, essentials: list, onOpen: (m) => opened = m);

    expect(find.text('Tu camino de hoy está completo'), findsOneWidget);
    expect(find.text('Disponible desde las 19:00'), findsOneWidget);
    await tester.tap(find.text('Cierra tu día con Dios'));
    expect(opened, isNull, reason: 'la noche no abre antes de las 19:00');
  });
}
