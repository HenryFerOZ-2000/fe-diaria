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
              missions: [...essentials, night],
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

  testWidgets('con la Palabra pendiente la centra con el versículo', (
    tester,
  ) async {
    await pump(tester, essentials: missions());

    expect(find.text('Ahora'), findsOneWidget);
    expect(find.textContaining('mira hacia atrás'), findsOneWidget);
    expect(find.text('0 de 3'), findsOneWidget);
  });

  testWidgets('centra el siguiente pendiente y marca los hechos', (
    tester,
  ) async {
    Mission? opened;
    final list = missions()..first.completed = true;
    await pump(tester, essentials: list, onOpen: (m) => opened = m);

    expect(find.text('Hecho'), findsOneWidget);
    await tester.tap(find.text('Comenzar').first);
    expect(opened?.id, 'morning');
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

  testWidgets('resiste 320 px y texto al 200 %', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: buildVerbumTheme(brightness: Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TodayJourneySection(
                missions: [...missions(), night],
                nightAvailable: true,
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
