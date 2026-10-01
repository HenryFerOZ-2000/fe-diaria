import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/design_system/design_system.dart';
import 'package:verbum/features/community/presentation/community_cover.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required ValueChanged<CommunityTab> onTab,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: buildVerbumTheme(brightness: Brightness.light),
          home: Scaffold(
            body: ListView(
              children: [
                CommunityCover(
                  image: AssetImage(VerbumPhotos.communityCandles.asset),
                  eyebrow: 'Fe que se comparte',
                  title: 'Comunidad',
                  subtitle: 'Nadie ora solo.',
                  extra: const CommunityGlassChip(
                    label: '24 intenciones esta semana',
                  ),
                  tab: CommunityTab.live,
                  onTab: onTab,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('el selector cambia de pestaña', (tester) async {
    CommunityTab? chosen;
    await pump(tester, onTab: (t) => chosen = t);
    expect(find.text('Comunidad'), findsOneWidget);
    await tester.tap(find.text('Mi comunidad'));
    expect(chosen, CommunityTab.mine);
  });

  testWidgets('la portada resiste 320 px y texto al 200 %', (tester) async {
    await pump(tester, onTab: (_) {}, size: const Size(320, 640), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
