import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:verbum/bible/data/bible_db.dart';
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
import 'package:verbum/screens/category_prayers_screen.dart';
import 'package:verbum/screens/emotion_passage_read_screen.dart';
import 'package:verbum/screens/intention_prayer_read_screen.dart';
import 'package:verbum/screens/novena_screen.dart';
import 'package:verbum/screens/prayer_read_screen.dart';
import 'package:verbum/screens/psalms_screen.dart';
import 'package:verbum/screens/reading_screen.dart';
import 'package:verbum/screens/traditional_prayer_screen.dart';
import 'package:verbum/screens/traditional_prayer_detail_screen.dart';
import 'package:verbum/services/traditional_prayers_service.dart';
import 'package:verbum/widgets/prayer_card.dart';
import 'package:verbum/widgets/prayer_reading_experience.dart';
import 'package:verbum/services/daily_progress_service.dart';
import 'package:verbum/services/language_service.dart';
import 'package:verbum/services/share_service.dart';
import 'package:verbum/services/spiritual_stats_service.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  DatabaseFactory? previousDatabaseFactory;
  final nativeShares = <MethodCall>[];

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
    previousDatabaseFactory = databaseFactoryOrNull;
    databaseFactory = databaseFactorySqflitePlugin;
    // Replace only SQLite's native boundary; passage resolution, provenance,
    // and the reader remain real.
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (call) async {
        switch (call.method) {
          case 'getDatabasesPath':
            return hiveDirectory.path;
          case 'openDatabase':
            return {'id': 1};
          case 'query':
            final args = (call.arguments as Map)['arguments'] as List?;
            if (args == null || args.length != 2) {
              return <Map<String, Object?>>[];
            }
            return [
              for (var verse = 1; verse <= 16; verse++)
                {
                  'book': args[0],
                  'chapter': args[1],
                  'verse': verse,
                  'text': 'Texto bíblico $verse.',
                },
            ];
          default:
            throw UnsupportedError('Unexpected SQLite call: ${call.method}');
        }
      },
    );
    await BibleDb.instance.init();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.box('favorites').clear();
    await Hive.box('settings').clear();
    await Hive.box('settings').put('adsRemoved', true);
    nativeShares.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async {
            nativeShares.add(call);
            return 'dev.fluttercommunity.plus/share/success';
          },
        );
  });

  tearDownAll(() async {
    databaseFactory = previousDatabaseFactory;
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  for (final entry in [
    ('Salmo 23', 'Salmo 23:1–6', ShareContentKind.psalm, 1, 6),
    ('Padre Nuestro', 'Mateo 6:9–13', ShareContentKind.verse, 9, 13),
  ]) {
    testWidgets('biblical traditional detail preserves ${entry.$1} reference', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TraditionalPrayerDetailScreen(
            religion: 'cristiana',
            category: 'biblicas',
            prayerKey: entry.$1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Compartir'));
      await _pumpRoute(tester);

      expect(find.byType(ShareComposerScreen), findsOneWidget);
      final content = _composer(tester).content;
      expect(content.title, entry.$1);
      expect(content.reference, entry.$2);
      expect(
        content.body,
        '${entry.$2}\n${[for (var verse = entry.$4; verse <= entry.$5; verse++) '$verse. Texto bíblico $verse.'].join('\n')}',
      );
      expect(content.sourceLabel, 'Reina-Valera 1909');
      expect(content.kind, entry.$3);
      expect(content.tradition, ShareTradition.evangelical);
      expect(nativeShares, isEmpty);
    });
  }

  for (final entry in <String, Widget>{
    'generic': const PrayerReadScreen(category: 'ansiedad'),
    'intention': const IntentionPrayerReadScreen(categoryKey: 'salud'),
    'emotion': const EmotionPassageReadScreen(emotionKey: 'ansiedad'),
    'traditional without religion metadata': const TraditionalPrayerScreen(
      prayerId: 'ave_maria',
    ),
  }.entries) {
    testWidgets('${entry.key} shares the displayed prayer and real reference', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: entry.value));
      await tester.pumpAndSettle();
      final reader = tester.widget<PrayerReadingExperience>(
        find.byType(PrayerReadingExperience),
      );
      expect(reader.text, isNotEmpty);

      await tester.tap(find.byTooltip('Compartir'));
      await _pumpRoute(tester);

      expect(find.byType(ShareComposerScreen), findsOneWidget);
      final content = _composer(tester).content;
      expect(content.title, reader.title);
      expect(content.body, reader.text);
      expect(content.reference, reader.verseReference ?? reader.title);
      expect(content.kind, ShareContentKind.prayer);
      expect(content.tradition, isNull);
      expect(content.sourceLabel, isNull);
      expect(nativeShares, isEmpty);
    });
  }

  for (final entry in {
    'catolica': ShareTradition.catholic,
    'cristiana': ShareTradition.evangelical,
    'general': ShareTradition.ecumenical,
  }.entries) {
    testWidgets('traditional detail preserves ${entry.key} metadata', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TraditionalPrayerDetailScreen(
            religion: entry.key,
            category: entry.key == 'catolica' ? 'basicas' : 'otras',
            prayerKey: entry.key == 'catolica'
                ? 'Padre Nuestro'
                : 'Oración de Entrega',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final reader = tester.widget<PrayerReadingExperience>(
        find.byType(PrayerReadingExperience),
      );
      expect(reader.text, isNotEmpty);
      await tester.tap(find.byTooltip('Compartir'));
      await _pumpRoute(tester);

      expect(find.byType(ShareComposerScreen), findsOneWidget);
      final content = _composer(tester).content;
      expect(content.title, reader.title);
      expect(content.body, reader.text);
      expect(content.reference, reader.title);
      expect(content.kind, ShareContentKind.prayer);
      expect(content.tradition, entry.value);
      expect(content.sourceLabel, isNull);
      expect(nativeShares, isEmpty);
    });
  }

  testWidgets('category prayer opens a composer with the displayed body', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryPrayerDetailScreen(categoryKey: 'familia'),
      ),
    );
    final prayer = tester.widget<PrayerCard>(find.byType(PrayerCard));
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is VIcon && w.icon == VerbumIcons.shareNetwork,
      ),
    );
    await _pumpRoute(tester);

    expect(find.byType(ShareComposerScreen), findsOneWidget);
    final content = _composer(tester).content;
    expect(content.title, 'Mi familia');
    expect(content.body, prayer.text);
    expect(content.reference, 'Mi familia');
    expect(content.kind, ShareContentKind.prayer);
    expect(content.tradition, isNull);
    expect(content.sourceLabel, isNull);
    expect(nativeShares, isEmpty);
  });

  testWidgets('novena preserves its day title and section reference', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await Hive.box('settings').put('traditionalPrayersReligion', 'catolica');
      await TraditionalPrayersService().loadPrayers();
    });
    final step = TraditionalPrayersService().getNovenaStep(1, 1)!;
    await tester.pumpWidget(const MaterialApp(home: NovenaDayScreen(day: 1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Compartir'));
    await _pumpRoute(tester);

    expect(find.byType(ShareComposerScreen), findsOneWidget);
    final content = _composer(tester).content;
    expect(content.title, 'Novena de Navidad - Día 1');
    expect(content.body, step['texto']);
    expect(content.reference, step['titulo']);
    expect(content.kind, ShareContentKind.prayer);
    expect(content.tradition, ShareTradition.catholic);
    expect(nativeShares, isEmpty);
  });

  testWidgets('a psalm card retains biblical provenance through its reader', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PsalmsScreen()));
    await tester.pumpAndSettle();
    final psalm = tester.widget<PrayerCard>(find.byType(PrayerCard).first);
    await tester.tap(find.text(psalm.title).first);
    await _pumpRoute(tester);
    await tester.tap(find.byTooltip('Compartir'));
    await _pumpRoute(tester);

    expect(find.byType(ShareComposerScreen), findsOneWidget);
    final content = _composer(tester).content;
    expect(content.title, psalm.title);
    expect(content.body, psalm.text);
    expect(content.reference, psalm.reference);
    expect(content.sourceLabel, 'Reina-Valera 1909');
    expect(content.kind, ShareContentKind.psalm);
    expect(nativeShares, isEmpty);
  });

  testWidgets(
    'the reading wrapper keeps a reference without inventing Scripture',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReadingScreen(
            title: 'Una pausa',
            content: 'Recuerda el bien recibido hoy.',
            reference: 'Reflexión del día',
            onComplete: () {},
          ),
        ),
      );
      await tester.tap(find.byTooltip('Compartir'));
      await _pumpRoute(tester);

      expect(find.byType(ShareComposerScreen), findsOneWidget);
      final content = _composer(tester).content;
      expect(content.title, 'Una pausa');
      expect(content.body, 'Recuerda el bien recibido hoy.');
      expect(content.reference, 'Reflexión del día');
      expect(content.kind, ShareContentKind.reflection);
      expect(content.tradition, isNull);
      expect(nativeShares, isEmpty);
    },
  );

  testWidgets('the reading wrapper preserves an explicit share callback', (
    tester,
  ) async {
    final shared = <(String, String?)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ReadingScreen(
          title: 'Una pausa',
          content: 'Recuerda el bien recibido hoy.',
          reference: 'Reflexión del día',
          onComplete: () {},
          onShare: (body, reference) => shared.add((body, reference)),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Compartir'));
    await _pumpRoute(tester);
    expect(shared, [('Recuerda el bien recibido hoy.', 'Reflexión del día')]);
    expect(find.byType(ShareComposerScreen), findsNothing);
    expect(nativeShares, isEmpty);
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
      icon: VerbumIcons.bookOpenText,
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
        icon: VerbumIcons.handHeart,
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

  testWidgets('an unavailable daily verse cannot open the composer', (
    tester,
  ) async {
    final mission = Mission(
      id: 'verse',
      title: 'Recibe la Palabra',
      description: 'Lee la Palabra de hoy.',
      icon: VerbumIcons.bookOpenText,
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

    expect(
      find.text('Versículo del día no disponible por el momento.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PrayerReadingExperience>(find.byType(PrayerReadingExperience))
          .onShare,
      isNull,
    );
    expect(find.byType(ShareComposerScreen), findsNothing);
    expect(nativeShares, isEmpty);
  });

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
        icon: VerbumIcons.flowerLotus,
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

// Keep the provider contract without starting unrelated database, notification,
// and widget-refresh work from AppProvider's constructor.
final class _EntryPointAppProvider extends ChangeNotifier
    implements AppProvider {
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
