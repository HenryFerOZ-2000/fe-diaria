import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';
import 'package:verbum/features/liturgy/domain/liturgical_day.dart';
import 'package:verbum/features/liturgy/domain/liturgical_source.dart';
import 'package:verbum/features/liturgy/presentation/liturgy_day_screen.dart';
import 'package:verbum/features/liturgy/presentation/liturgy_source_sheet.dart';
import 'package:verbum/features/liturgy/presentation/today_liturgy_card.dart';

const cardTestSource = LiturgicalSource(
  id: 'romcal-general-roman-es',
  name: 'Romcal — Calendario Romano General',
  url: 'https://github.com/romcal/romcal',
  license: 'MIT',
  revision: '6246bad8c548c1f2528916df40e433c1f7c97c6a',
  scope: CalendarScope.generalRoman,
  authorityStatus: AuthorityStatus.openEcclesialSource,
  generatedAt: '2026-09-20T00:00:00.000Z',
  reviewedAt: '2026-09-20',
  reviewNotes: 'Calendario Romano General; propios de Ecuador no incluidos.',
);

LiturgicalDay cardDay(String name, List<String> colors) {
  return LiturgicalDay.fromJson({
    'date': '2026-09-20',
    'primary': {
      'id': 'ordinary_time_25_sunday',
      'name': name,
      'rank': 'sunday',
      'colors': colors,
    },
    'optional': const [],
    'season': 'ordinaryTime',
    'sundayCycle': 'C',
    'weekdayCycle': 'II',
    'psalterWeek': 1,
  }, source: cardTestSource);
}

void main() {
  testWidgets('la tarjeta resiste 320 px y texto al 200 %', (tester) async {
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
              child: TodayLiturgyCard(
                day: cardDay(
                  'Domingo de nombre deliberadamente extenso para probar el diseño',
                  ['green'],
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('HOY EN LA IGLESIA'), findsOneWidget);
    expect(find.text('Ver el día'), findsOneWidget);
  });

  testWidgets('el blanco litúrgico conserva borde y etiqueta textual', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayLiturgyCard(
            day: cardDay('Solemnidad de prueba', ['white']),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('Blanco'), findsOneWidget);
    final decoration =
        tester
                .widget<Container>(
                  find.byKey(const Key('liturgical_color_marker')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('el blanco litúrgico mantiene contraste en modo oscuro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TodayLiturgyCard(
            day: cardDay('Solemnidad de prueba', ['white']),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Blanco'), findsOneWidget);
  });

  testWidgets('un día sin color usa un acento neutro seguro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayLiturgyCard(
            day: cardDay('Sábado Santo', const []),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Sin color indicado'), findsOneWidget);
  });

  testWidgets('Ecuador elegido con fuente general explica el fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLiturgySourceSheet(
              context,
              day: cardDay('Domingo', ['green']),
              selection: CalendarSelection.country('EC'),
            ),
            child: const Text('Fuente'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Fuente'));
    await tester.pumpAndSettle();
    expect(find.text('Calendario Romano General'), findsOneWidget);
    expect(
      find.textContaining('contenido local de Ecuador aún no está disponible'),
      findsOneWidget,
    );
  });

  testWidgets('el detalle resiste 320 px y texto al 200 %', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: LiturgyDayScreen(
            day: cardDay(
              'Domingo de nombre deliberadamente extenso para probar el detalle',
              ['green'],
            ),
            selection: const CalendarSelection.generalRoman(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Oración devocional sugerida para hoy'), findsOneWidget);
  });
}
