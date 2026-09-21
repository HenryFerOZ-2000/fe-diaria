import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:verbum/bible/ui/catholic_bible_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verbum/bible/domain/bible_book_info.dart';
import 'package:verbum/bible/domain/catholic_bible_catalog.dart';
import 'package:verbum/bible/domain/verse.dart';
import 'package:verbum/bible/services/bible_reading_preferences.dart';
import 'package:verbum/faith/content_provenance.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/faith/tradition_capabilities.dart';
import 'package:verbum/data/spiritual_paths_catalog.dart';
import 'package:verbum/screens/content_sources_screen.dart';
import 'package:verbum/services/traditional_prayers_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la liturgia católica no es capacidad evangélica ni general', () {
    expect(
      TraditionCapabilities.forTradition(
        FaithTradition.catholic,
      ).showDailyLiturgy,
      isTrue,
    );
    expect(
      TraditionCapabilities.forTradition(
        FaithTradition.evangelical,
      ).showDailyLiturgy,
      isFalse,
    );
    expect(
      TraditionCapabilities.forTradition(
        FaithTradition.general,
      ).showDailyLiturgy,
      isFalse,
    );
    expect(
      TraditionCapabilities.forTradition(FaithTradition.unset).showDailyLiturgy,
      isFalse,
    );
    expect(
      faithTraditionFromStorageString('desconocida'),
      FaithTradition.unset,
    );
  });

  test('las citas RV1909 conservan literalmente Jehová', () {
    final texts = SpiritualPathsCatalog.paths
        .expand((path) => path.days)
        .map((day) => day.scripture);
    expect(texts.any((text) => text.contains('Jehová')), isTrue);
  });

  testWidgets('fuentes explica el alcance general y la convención católica', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ContentSourcesScreen()));
    await tester.scrollUntilVisible(
      find.text('Calendario Romano General'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Calendario Romano General'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cómo nombramos a Dios'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Dios o Señor'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('La Biblia sin conexión'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('dominio público'), findsOneWidget);
  });

  testWidgets('consulta católica cabe con texto grande y teclado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
            viewInsets: EdgeInsets.only(bottom: 260),
          ),
          child: CatholicBibleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('cada canon conserva libros únicos y testamentos correctos', () {
    expect(bibleBooks.length, 66);
    expect(
      bibleBooks.where((b) => b.testament == BibleTestament.old).length,
      39,
    );
    expect(catholicBibleBooks.length, 73);
    expect(catholicBibleBooks.map((b) => b.id).toSet().length, 73);
    expect(
      catholicBibleBooks.where((b) => b.testament == BibleTestament.old).length,
      46,
    );
    expect(
      catholicBibleBooks
          .where((b) => b.testament == BibleTestament.newTestament)
          .length,
      27,
    );
    expect(catholicSupplementPages.length, 3);
    for (final page in catholicBookPages.values) {
      expect(Uri.parse('$catholicBibleSource$page').host, 'www.vatican.va');
    }
  });

  test(
    'cristiana general dispone de catálogo sin devociones exclusivas',
    () async {
      final service = TraditionalPrayersService();
      await service.loadPrayers();
      expect(service.getCategories('general'), isNotEmpty);
      expect(service.getCategories('general'), isNot(contains('arcangeles')));
      expect(service.getPrayer('general', 'basicas', 'Ave María'), isNull);
      expect(service.getCategories('desconocida'), isEmpty);
    },
  );

  test('Salmo 91 usa los 16 versículos locales y declara edición', () async {
    final prayer = await TraditionalPrayersService().readPrayer(
      'general',
      'biblicas',
      'Salmo 91',
      chapterLoader: (book, chapter) async {
        expect(book, 'PSA');
        expect(chapter, 91);
        return List.generate(
          16,
          (i) => Verse(
            book: book,
            chapter: chapter,
            verse: i + 1,
            text: 'Texto ${i + 1}',
          ),
        );
      },
    );
    expect(prayer, isNotNull);
    expect(prayer!['texto'], contains('16. Texto 16'));
    expect(
      (prayer['provenance'] as ContentProvenance).translation,
      'Reina-Valera 1909',
    );
  });

  test('un pasaje incompleto no se sustituye por una copia antigua', () async {
    expect(
      TraditionalPrayersService().readPrayer(
        'cristiana',
        'biblicas',
        'Salmo 91',
        chapterLoader: (_, _) async => [],
      ),
      throwsStateError,
    );
  });

  test('una oración desconocida no recibe atribución inventada', () {
    final source = ContentProvenance.forPrayer('Oración por la Familia');
    expect(source.sourceUrl, isNull);
    expect(source.reviewStatus, contains('Pendiente'));
  });

  test(
    'la composición del catálogo usa una etiqueta devocional discreta',
    () async {
      final prayer = await TraditionalPrayersService().readPrayer(
        'general',
        'otras',
        'Oración por la Familia',
      );
      final source = prayer!['provenance'] as ContentProvenance;
      expect(source.kind, 'Oración devocional de Verbum');
      expect(source.description, isNot(contains('IA')));
      expect(source.licenseStatus, isNot(contains('IA')));
      expect(source.sourceUrl, isNull);
      expect(source.reviewStatus, contains('revisión editorial'));
    },
  );

  test(
    'obtener una fórmula tradicional con IA no la convierte en original',
    () async {
      final prayer = await TraditionalPrayersService().readPrayer(
        'catolica',
        'basicas',
        'Padre Nuestro',
      );
      final source = prayer!['provenance'] as ContentProvenance;
      expect(source.kind, 'Oración tradicional');
      expect(source.sourceUrl, contains('vatican.va'));
      final michael = await TraditionalPrayersService().readPrayer(
        'catolica',
        'arcangeles',
        'San Miguel Arcángel',
      );
      final michaelSource = michael!['provenance'] as ContentProvenance;
      expect(michaelSource.kind, 'Oración tradicional');
      expect(michaelSource.description, isNot(contains('IA')));
    },
  );

  test('se conservan lectura y subrayados existentes de RV1909', () async {
    SharedPreferences.setMockInitialValues({
      'bible_last_book_id': 'JHN',
      'bible_last_book_name': 'Juan',
      'bible_last_chapter': 3,
      'bible_last_verse': 16,
      'bible_highlights': ['JHN:3:16'],
    });
    final prefs = BibleReadingPreferences();
    expect((await prefs.getLastPosition())!.verse, 16);
    expect(await prefs.getHighlights(), contains('JHN:3:16'));
    expect(prefs.highlightKey('JHN', 3, 16), 'JHN:3:16');
  });
}
