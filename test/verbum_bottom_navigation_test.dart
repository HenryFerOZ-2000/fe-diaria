import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';
import 'package:verbum/widgets/verbum_bottom_navigation.dart';

void main() {
  Future<void> pumpNavigation(
    WidgetTester tester, {
    required Size size,
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerbumTheme(brightness: Brightness.light),
        home: Scaffold(
          bottomNavigationBar: VerbumBottomNavigation(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cinco destinos con nombre accesible en 320 px', (tester) async {
    int? tapped;
    await pumpNavigation(
      tester,
      size: const Size(320, 640),
      onSelected: (i) => tapped = i,
    );

    for (final label in ['Hoy', 'Biblia', 'Oraciones', 'Comunidad', 'Chat']) {
      expect(find.byTooltip(label), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Biblia'));
    expect(tapped, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el destino activo va relleno; Oraciones siempre destaca', (
    tester,
  ) async {
    await pumpNavigation(tester, size: const Size(390, 844), selectedIndex: 1);

    final filled = tester
        .widgetList<VIcon>(find.byType(VIcon))
        .where((i) => i.weight == VIconWeight.fill)
        .map((i) => i.icon)
        .toSet();
    expect(filled, {VerbumIcons.bookOpenText, VerbumIcons.handsPraying});
  });

  testWidgets('el botón central abre Oraciones', (tester) async {
    int? tapped;
    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      onSelected: (i) => tapped = i,
    );
    await tester.tap(find.byTooltip('Oraciones'));
    expect(tapped, 2);
  });
}
