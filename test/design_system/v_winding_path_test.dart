import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  testWidgets('los pasos bloqueados no se abren y resiste texto al 200 %', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <int>[];
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 1400),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: buildVerbumTheme(brightness: Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: VWindingPath(
                steps: [
                  for (var i = 1; i <= 3; i++)
                    VWindingStep(
                      photo: VerbumPhotos.lake,
                      title: 'Día $i · Un título largo para el paso',
                      semanticLabel: 'Día $i',
                      onTap: i < 3 ? () => opened.add(i) : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel('Día 2'));
    await tester.tap(find.bySemanticsLabel('Día 3'));
    expect(opened, [2]);
  });
}
