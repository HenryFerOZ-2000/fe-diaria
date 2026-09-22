import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verbum/bible/domain/verse.dart' as bible;
import 'package:verbum/bible/ui/bible_verses_screen.dart';
import 'package:verbum/controllers/missions_controller.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';
import 'package:verbum/features/sharing/presentation/share_composer_screen.dart';
import 'package:verbum/models/spiritual_path.dart';
import 'package:verbum/models/verse.dart';
import 'package:verbum/providers/app_provider.dart';
import 'package:verbum/screens/daily_missions_flow_screen.dart';
import 'package:verbum/screens/favorites_screen.dart';
import 'package:verbum/screens/mission_read_screen.dart';
import 'package:verbum/screens/spiritual_path_day_screen.dart';
import 'package:verbum/services/daily_progress_service.dart';
import 'package:verbum/services/language_service.dart';
import 'package:verbum/services/share_service.dart';
import 'package:verbum/services/spiritual_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUpAll(() async {
    setupFirebaseCoreMocks();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final event in ['auth-state', 'id-token']) {
      messenger.setMockMethodCallHandler(
        MethodChannel('plugins.flutter.io/firebase_auth/$event/[DEFAULT]'),
        (_) async => null,
      );
    }
    await Firebase.initializeApp();

    hiveDirectory = await Directory.systemTemp.createTemp(
      'verbum_share_entry_points_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox('favorites');
    await Hive.openBox('settings');
    await Hive.openBox('verse_cache');
    await Hive.openBox('prayer_cache');
    await LanguageService.init();
    await LanguageService.setLanguage('es');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.box('favorites').clear();
    await Hive.box('settings').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('the facade opens one composer with the exact content', (
    tester,
  ) async {
    final content = ShareContent(
      title: 'Recibe la Palabra',
      body: 'Porque de tal manera amó Dios al mundo.',
      reference: 'Juan 3:16 · RV1909',
      kind: ShareContentKind.verse,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => ShareService.openComposer(context, content),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await _pumpRoute(tester);

    expect(find.byType(ShareComposerScreen), findsOneWidget);
    expect(_composer(tester).content, same(content));
  });

  testWidgets('a Bible selection keeps its body, reference, and RV1909', (
    tester,
  ) async {
    const verseText = 'Porque de tal manera amó Dios al mundo.';
    await tester.pumpWidget(
      MaterialApp(
        home: BibleVersesScreen(
          bookId: 'JHN',
          bookName: 'Juan',
          chapter: 3,
          initialVerse: 16,
          chapterLoader: (_, _) async => [
            bible.Verse(book: 'JHN', chapter: 3, verse: 16, text: verseText),
          ],
          chaptersLoader: (_) async => const [3],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText() == '16  $verseText',
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Compartir'));
    await _pumpRoute(tester);

    final content = _composer(tester).content;
    expect(content.title, 'Juan 3');
    expect(content.body, '16. $verseText');
    expect(content.reference, 'Juan 3:16 · RV1909');
    expect(content.kind, ShareContentKind.verse);
  });

  testWidgets('a favorite opens verse content with its real RV1909 reference', (
    tester,
  ) async {
    final verse = Verse(
      id: 1,
      text: 'Jehová es mi pastor; nada me faltará.',
      reference: 'Salmos 23:1',
      book: 'PSA',
      chapter: 23,
      verse: 1,
    );
    final provider = _EntryPointAppProvider(
      testFavorites: [verse],
      testTodayVerse: verse,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(home: FavoritesScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Compartir'));
    await _pumpRoute(tester);

    final content = _composer(tester).content;
    expect(content.title, 'Favorito');
    expect(content.body, verse.text);
    expect(content.reference, 'Salmos 23:1 · RV1909');
    expect(content.kind, ShareContentKind.verse);
  });

  testWidgets('receive-the-Word remains verse content with RV1909', (
    tester,
  ) async {
    final verse = Verse(
      id: 2,
      text: 'La paz os dejo, mi paz os doy.',
      reference: 'Juan 14:27',
      book: 'JHN',
      chapter: 14,
      verse: 27,
    );
    final mission = Mission(
      id: 'verse',
      title: 'Recibe la Palabra',
      description: 'Lee la Palabra de hoy.',
      icon: Icons.menu_book_rounded,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyMissionsFlowScreen(
          missions: [mission],
          initialMissionIndex: 0,
          provider: _EntryPointAppProvider(
            testFavorites: const [],
            testTodayVerse: verse,
          ),
          missionsController: MissionsController(missions: [mission]),
          dailyProgressService: DailyProgressService(),
          spiritualStatsService: SpiritualStatsService(),
          onMissionComplete: (_) {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Compartir'));
    await _pumpRoute(tester);

    final content = _composer(tester).content;
    expect(content.title, 'Recibe la Palabra');
    expect(content.body, verse.text);
    expect(content.reference, 'Juan 14:27 · RV1909');
    expect(content.kind, ShareContentKind.verse);
  });

  testWidgets(
    'another Today mission stays mission content without a fake reference',
    (tester) async {
      final mission = Mission(
        id: 'practice',
        title: 'Un gesto de bondad',
        description: 'Lleva la fe a lo cotidiano.',
        content: 'Ayuda hoy a una persona sin esperar nada a cambio.',
        icon: Icons.volunteer_activism_outlined,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DailyMissionsFlowScreen(
            missions: [mission],
            initialMissionIndex: 0,
            provider: _EntryPointAppProvider(
              testFavorites: const [],
              testTodayVerse: null,
            ),
            missionsController: MissionsController(missions: [mission]),
            dailyProgressService: DailyProgressService(),
            spiritualStatsService: SpiritualStatsService(),
            onMissionComplete: (_) {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Compartir'));
      await _pumpRoute(tester);

      final content = _composer(tester).content;
      expect(content.title, mission.title);
      expect(content.body, mission.content);
      expect(content.reference, isNull);
      expect(content.kind, ShareContentKind.mission);
    },
  );

  testWidgets('the mission reader opens mission content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MissionReadScreen(
          title: 'Ora por alguien',
          content: 'Pon delante de Dios a una persona que lo necesite.',
          onCompleted: () {},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Compartir'));
    await _pumpRoute(tester);

    final content = _composer(tester).content;
    expect(content.title, 'Ora por alguien');
    expect(content.body, 'Pon delante de Dios a una persona que lo necesite.');
    expect(content.reference, isNull);
    expect(content.kind, ShareContentKind.mission);
  });

  testWidgets(
    'spiritual-path Scripture opens verse content, not an invitation',
    (tester) async {
      const day = SpiritualPathDay(
        number: 1,
        title: 'Dios permanece cerca',
        subtitle: 'Reconoce su compañía',
        scriptureReference: 'Salmo 34:18',
        scripture: 'Cercano está Jehová a los quebrantados de corazón.',
        reflection: 'Dios no abandona.',
        prayer: 'Dios cercano, acompáñame.',
        practice: 'Haz una pausa.',
      );
      const secondDay = SpiritualPathDay(
        number: 2,
        title: 'Camina con esperanza',
        subtitle: 'Da el siguiente paso',
        scriptureReference: 'Romanos 15:13',
        scripture: 'El Dios de esperanza os llene de todo gozo.',
        reflection: 'La esperanza permanece.',
        prayer: 'Dame esperanza.',
        practice: 'Da un paso.',
      );
      const path = SpiritualPath(
        id: 'test_path',
        title: 'Volver a confiar',
        subtitle: 'Un camino sereno',
        description: 'Dos días de prueba.',
        category: 'Esperanza',
        minutesPerDay: 5,
        icon: Icons.spa_outlined,
        accent: Color(0xFF6B7398),
        days: [day, secondDay],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SpiritualPathDayScreen(
            path: path,
            dayNumber: 1,
            completeDay: (_, _, _) async {},
          ),
        ),
      );

      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(3);
      await tester.pump();
      await tester.tap(find.text('Completar este día'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Compartir'));
      await _pumpRoute(tester);

      final content = _composer(tester).content;
      expect(content.title, path.title);
      expect(content.body, day.scripture);
      expect(content.reference, 'Salmo 34:18 · RV1909');
      expect(content.kind, ShareContentKind.verse);
    },
  );
}

ShareComposerScreen _composer(WidgetTester tester) =>
    tester.widget<ShareComposerScreen>(find.byType(ShareComposerScreen));

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

final class _EntryPointAppProvider extends AppProvider {
  _EntryPointAppProvider({
    required this.testFavorites,
    required this.testTodayVerse,
  });

  final List<Verse> testFavorites;
  final Verse? testTodayVerse;

  @override
  List<Verse> get favorites => testFavorites;

  @override
  Verse? get todayVerse => testTodayVerse;

  @override
  Future<void> toggleFavorite(Verse verse) async {}
}
