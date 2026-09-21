import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/faith/content_provenance.dart';
import 'package:verbum/widgets/prayer_reading_experience.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildReader({double textScale = 1, Size size = const Size(360, 640)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: PrayerReadingExperience(
          loading: false,
          provenance: ContentProvenance.bible,
          category: 'Palabra de hoy',
          title: 'Recibe la Palabra',
          text:
              'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito.',
          verseReference: 'Juan 3:16',
          accent: const Color(0xFF77649A),
          onBack: () {},
          onComplete: () {},
          onNext: () {},
          primaryActionLabel: 'He recibido la Palabra',
          secondaryActionLabel: 'Conversar sobre este versículo',
          secondaryActionIcon: Icons.forum_outlined,
          onSecondaryAction: () {},
        ),
      ),
    );
  }

  testWidgets('el lector no desborda en pantalla estrecha con texto al 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildReader(textScale: 2, size: const Size(320, 568)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el lector no muestra una tarjeta de procedencia', (
    tester,
  ) async {
    await tester.pumpWidget(buildReader());

    expect(find.text('Acerca de este texto'), findsNothing);
  });

  testWidgets('un versículo identifica discretamente su edición', (
    tester,
  ) async {
    await tester.pumpWidget(buildReader());

    expect(find.text('Juan 3:16'), findsOneWidget);
    expect(find.text('RV1909'), findsOneWidget);
  });
}
