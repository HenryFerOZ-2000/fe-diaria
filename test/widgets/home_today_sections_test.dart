import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/liturgy/presentation/today_liturgy_card.dart';
import 'package:verbum/features/liturgy/presentation/today_liturgy_section.dart';
import 'package:verbum/widgets/home_today_sections.dart';

import '../features/liturgy/today_liturgy_section_test.dart'
    show FakeLiturgyService, catholicDay;

void main() {
  testWidgets('las misiones preceden al camino y la liturgia queda al final', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeTodaySections(
            missions: const SizedBox(key: Key('missions'), height: 100),
            spiritualPath: const SizedBox(key: Key('path'), height: 80),
            liturgy: TodayLiturgySection(
              service: FakeLiturgyService(day: catholicDay),
              tradition: FaithTradition.catholic,
              scheduleRefresh: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final missions = tester.getRect(find.byKey(const Key('missions')));
    final path = tester.getRect(find.byKey(const Key('path')));
    final liturgy = tester.getRect(find.byType(TodayLiturgyCard));
    expect(missions.bottom, lessThan(path.top));
    expect(path.bottom, lessThan(liturgy.top));
    expect(liturgy.top - path.bottom, 16);
  });

  for (final tradition in [
    FaithTradition.evangelical,
    FaithTradition.catholic,
  ]) {
    testWidgets('liturgia ausente no deja huecos ($tradition)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTodaySections(
              missions: const SizedBox(key: Key('missions'), height: 100),
              spiritualPath: const SizedBox(key: Key('path'), height: 80),
              liturgy: TodayLiturgySection(
                service: FakeLiturgyService(),
                tradition: tradition,
                scheduleRefresh: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final content = tester.getRect(find.byType(HomeTodaySections));
      final missions = tester.getRect(find.byKey(const Key('missions')));
      final path = tester.getRect(find.byKey(const Key('path')));
      expect(missions.top, content.top);
      expect(path.top - missions.bottom, 22);
      expect(content.bottom, path.bottom);
      expect(find.byType(TodayLiturgyCard), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
