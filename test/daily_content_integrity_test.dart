import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:verbum/services/cache_service.dart';
import 'package:verbum/services/daily_content_service.dart';
import 'package:verbum/services/prayer_service.dart';
import 'package:verbum/models/prayer.dart';
import 'package:verbum/models/verse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });

  test('el paquete incluye ambas colecciones evangélicas', () async {
    final assets = await AssetManifest.loadFromAssetBundle(rootBundle);
    expect(
      assets.listAssets(),
      containsAll([
        'assets/traditions/evangelical/morning_prayers.json',
        'assets/traditions/evangelical/night_prayers.json',
      ]),
    );
  });

  test('cada petición concurrente espera hasta tener contenido', () async {
    final service = DailyContentService()..clearCache();
    final first = service.loadContent();
    final second = service.loadContent();
    await second;
    try {
      expect(service.getMorningPrayer, returnsNormally);
    } finally {
      await first;
    }
  });

  test('limpiar durante una carga no publica un catálogo parcial', () async {
    final assets = <String, ByteData>{};
    for (final key in [
      'assets/data/verses.json',
      'assets/data/morning_prayers.json',
      'assets/data/night_prayers.json',
      'assets/data/prayers_by_intention.json',
      'assets/traditions/evangelical/morning_prayers.json',
      'assets/traditions/evangelical/night_prayers.json',
    ]) {
      assets[key] = await rootBundle.load(key);
      rootBundle.evict(key);
    }
    final requested = Completer<void>();
    final release = Completer<void>();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      if (key == 'assets/data/morning_prayers.json') {
        requested.complete();
        await release.future;
      }
      return assets[key];
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final service = DailyContentService()..clearCache();
    final loading = service.loadContent();
    await requested.future;
    service.clearCache();
    release.complete();
    await loading;
    expect(service.getTodayVerse(), isNotEmpty);
    expect(service.getNightPrayer(tradition: 'general'), isNotEmpty);
  });

  test(
    'la selección general y evangélica usa su catálogo empaquetado',
    () async {
      final service = DailyContentService()..clearCache();
      await service.loadContent();
      final morning =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/traditions/evangelical/morning_prayers.json',
                ),
              )
              as List;
      final night =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/traditions/evangelical/night_prayers.json',
                ),
              )
              as List;
      for (final tradition in ['general', 'cristiana']) {
        expect(
          morning,
          contains(service.getMorningPrayer(tradition: tradition)),
        );
        expect(
          night.map((e) => e['text']),
          contains(service.getNightPrayer(tradition: tradition)),
        );
      }
    },
  );

  group('caché de oraciones por tradición', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('verbum-content-test-');
      Hive.init(directory.path);
      await Hive.openBox('settings');
      await CacheService.init();
      PrayerService().resetInMemoryDailyPrayers();
      DailyContentService().clearCache();
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test(
      'una caché bíblica legacy no se presenta como RV1909 verificada',
      () async {
        final now = DateTime.now();
        final date = '${now.year}-${now.month}-${now.day}';
        final box = Hive.box('verse_cache');
        await box.put('last_verse_date', date);
        await box.put(
          'today_verse',
          Verse(
            id: 1,
            text: 'Paráfrasis antigua sin edición documentada',
            reference: 'Referencia antigua',
            book: 'OLD',
            chapter: 1,
            verse: 1,
          ).toJson(),
        );

        expect(CacheService.getTodayVerse(), isNull);
        expect(CacheService.getLastVerse(), isNull);
      },
    );

    test('la caché nueva conserva la edición RV1909 verificada', () async {
      final verse = Verse(
        id: 20260921,
        text: 'Jehová es mi pastor; nada me faltará.',
        reference: 'Salmos 23:1',
        book: 'PSA',
        chapter: 23,
        verse: 1,
      );

      await CacheService.saveTodayVerse(verse);

      expect(CacheService.getTodayVerse()?.text, verse.text);
      expect(CacheService.getLastVerse()?.reference, verse.reference);
    });

    test('una caché legacy sin tradición no se presume evangélica', () async {
      await Hive.box('settings').put('traditionalPrayersReligion', 'general');
      await CacheService.saveTodayPrayer(
        Prayer(
          id: 1750000000000,
          text: 'Texto de procedencia desconocida',
          type: 'morning',
          title: 'Oración antigua',
        ),
      );
      final prayer = await PrayerService().getTodayMorningPrayer();
      expect(prayer.id, inInclusiveRange(60001, 60366));
      expect(
        prayer.text,
        DailyContentService().getMorningPrayer(tradition: 'general'),
      );
    });

    test(
      'cambiar tradición no conserva la noche anterior en memoria',
      () async {
        final settings = Hive.box('settings');
        await settings.put('traditionalPrayersReligion', 'catolica');
        final service = PrayerService();
        final catholicNight = await service.getTodayEveningPrayer();
        expect(catholicNight.id, lessThan(50000));
        await settings.put('traditionalPrayersReligion', 'cristiana');
        await service.getTodayMorningPrayer();
        final evangelicalNight = await service.getTodayEveningPrayer();
        expect(evangelicalNight.id, inInclusiveRange(70001, 70366));
        expect(
          evangelicalNight.text,
          DailyContentService().getNightPrayer(tradition: 'cristiana'),
        );
      },
    );

    test(
      'las peticiones en vuelo conservan su tradición al completarse',
      () async {
        final settings = Hive.box('settings');
        await settings.put('traditionalPrayersReligion', 'catolica');
        final service = PrayerService();
        final oldMorning = service.getTodayMorningPrayer();
        final changed = settings.put('traditionalPrayersReligion', 'general');
        final newNight = service.getTodayEveningPrayer();
        await Future.wait([oldMorning, newNight, changed]);
        final newMorning = await service.getTodayMorningPrayer();
        expect(newMorning.id, inInclusiveRange(60001, 60366));
      },
    );
  });
}
