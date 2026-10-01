import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  testWidgets('el regreso compartido aparece solo cuando se puede volver', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: buildVerbumTheme(brightness: Brightness.light),
        home: const Scaffold(appBar: VAppBar(title: Text('Inicio'))),
      ),
    );
    expect(find.byType(VBackButton), findsNothing);

    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(appBar: VAppBar(title: Text('Detalle'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VBackButton), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);
  });
}
