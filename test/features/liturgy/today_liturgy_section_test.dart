import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/liturgy/application/liturgy_service.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';
import 'package:verbum/features/liturgy/domain/liturgical_day.dart';
import 'package:verbum/features/liturgy/domain/liturgical_source.dart';
import 'package:verbum/features/liturgy/presentation/liturgy_day_screen.dart';
import 'package:verbum/features/liturgy/presentation/today_liturgy_section.dart';

const sectionTestSource = LiturgicalSource(
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

final class FakeLiturgyService implements DailyLiturgyLoader {
  FakeLiturgyService({this.day, this.error});

  final LiturgicalDay? day;
  final Object? error;
  int calls = 0;

  @override
  Future<LiturgicalDay?> today() async {
    calls++;
    if (error != null) throw error!;
    return day;
  }

  @override
  Duration untilNextDay() => const Duration(hours: 12);
}

final catholicDay = LiturgicalDay.fromJson({
  'date': '2026-09-20',
  'primary': {
    'id': 'ordinary_time_25_sunday',
    'name': 'XXV Domingo del Tiempo Ordinario',
    'rank': 'sunday',
    'colors': ['green'],
  },
  'optional': const [],
  'season': 'ordinaryTime',
  'sundayCycle': 'C',
  'weekdayCycle': 'II',
  'psalterWeek': 1,
}, source: sectionTestSource);

void main() {
  testWidgets('no consulta ni muestra liturgia para tradición evangélica', (
    tester,
  ) async {
    final service = FakeLiturgyService(day: catholicDay);
    await tester.pumpWidget(
      MaterialApp(
        home: TodayLiturgySection(
          service: service,
          tradition: FaithTradition.evangelical,
          scheduleRefresh: false,
        ),
      ),
    );
    await tester.pump();
    expect(service.calls, 0);
    expect(find.text('HOY EN LA IGLESIA'), findsNothing);
  });

  testWidgets('un fallo del repositorio no rompe la pantalla', (tester) async {
    final service = FakeLiturgyService(error: const FormatException('asset'));
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            const Text('Hoy sigue visible'),
            TodayLiturgySection(
              service: service,
              tradition: FaithTradition.catholic,
              scheduleRefresh: false,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hoy sigue visible'), findsOneWidget);
    expect(find.text('HOY EN LA IGLESIA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('católica carga y recarga al comenzar el día siguiente', (
    tester,
  ) async {
    final service = FakeLiturgyService(day: catholicDay);
    await tester.pumpWidget(
      MaterialApp(
        home: TodayLiturgySection(
          service: service,
          tradition: FaithTradition.catholic,
          scheduleRefresh: true,
        ),
      ),
    );
    await tester.pump();
    expect(service.calls, 1);
    expect(find.text('HOY EN LA IGLESIA'), findsOneWidget);

    await tester.pump(const Duration(hours: 12));
    await tester.pump();
    expect(service.calls, 2);
  });

  testWidgets('la tarjeta católica abre el detalle del día', (tester) async {
    final service = FakeLiturgyService(day: catholicDay);
    await tester.pumpWidget(
      MaterialApp(
        home: TodayLiturgySection(
          service: service,
          tradition: FaithTradition.catholic,
          selection: CalendarSelection.country('EC'),
          scheduleRefresh: false,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Ver el día'));
    await tester.pumpAndSettle();
    final screen = tester.widget<LiturgyDayScreen>(
      find.byType(LiturgyDayScreen),
    );
    expect(screen.selection, CalendarSelection.country('EC'));
  });
}
