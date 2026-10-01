import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    for (final width in [132.0, 164.0]) {
      testWidgets('la fila de fotos cabe con título largo (x$scale, $width)', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildVerbumTheme(brightness: Brightness.light),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Builder(
                  builder: (context) => SizedBox(
                    height: VPhotoCard.rowHeight(context, width),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        VPhotoCard(
                          photo: VerbumPhotos.candle,
                          title: 'Novena de Navidad para toda la familia',
                          caption: 'Nueve días de preparación',
                          width: width,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
