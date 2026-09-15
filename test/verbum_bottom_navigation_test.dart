import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
              selectedIndex: 2,
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
}
