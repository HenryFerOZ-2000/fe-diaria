import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';
import 'package:verbum/features/today/application/today_schedule.dart';
import 'package:verbum/features/today/presentation/day_hour_icons.dart';
import 'package:verbum/widgets/verbum_bottom_navigation.dart';

void main() {
  Future<void> pumpNavigation(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            bottomNavigationBar: VerbumBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los cinco destinos en una pantalla de 320 px', (
    tester,
  ) async {
    await pumpNavigation(tester, size: const Size(320, 640));

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Comunidad'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Oraciones'), findsOneWidget);
    expect(find.text('Biblia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resiste texto ampliado sin desbordarse', (tester) async {
    await pumpNavigation(tester, size: const Size(360, 720), textScale: 2);

    expect(tester.takeException(), isNull);
  });

  testWidgets('usa iconos SVG y marca el destino activo con peso relleno', (
    tester,
  ) async {
    await pumpNavigation(tester, size: const Size(390, 844));

    final icons = tester.widgetList<VIcon>(find.byType(VIcon)).toList();
    expect(icons.where((i) => i.icon == VerbumIcons.handsPraying), isNotEmpty);
    expect(icons.where((i) => i.icon == VerbumIcons.bookOpenText), isNotEmpty);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    // selectedIndex 0 = Hoy: su icono va relleno, los demás en regular.
    final filled = icons.where((i) => i.weight == VIconWeight.fill).toList();
    expect(filled, hasLength(1));
    expect(filled.single.icon, iconForDayHour(dayHourFor(DateTime.now())));
  });

  test('el icono de Hoy sigue las horas del día', () {
    expect(iconForDayHour(DayHour.morning), VerbumIcons.sunHorizon);
    expect(iconForDayHour(DayHour.midday), VerbumIcons.sun);
    expect(iconForDayHour(DayHour.night), VerbumIcons.moonStars);
  });
}
