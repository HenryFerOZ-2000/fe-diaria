import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  testWidgets('cuatro acciones y cerrar caben en 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerbumTheme(brightness: Brightness.light),
        home: Scaffold(
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: VActionBar(
              leading: '2 versículos',
              onClose: () {},
              items: [
                for (final (icon, label) in const [
                  (VerbumIcons.pencilSimple, 'Resaltar'),
                  (VerbumIcons.copy, 'Copiar'),
                  (VerbumIcons.shareNetwork, 'Compartir'),
                  (VerbumIcons.sparkle, 'Reflexionar'),
                ])
                  VActionBarItem(icon: icon, label: label, onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
