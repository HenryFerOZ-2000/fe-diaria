import 'dart:convert';
import 'package:flutter/services.dart';
import '../bible/data/bible_db.dart';
import '../bible/domain/verse.dart';
import '../faith/content_provenance.dart';
import '../faith/biblical_prayer_passages.dart';

/// Servicio para gestionar las oraciones tradicionales
class TraditionalPrayersService {
  static final TraditionalPrayersService _instance =
      TraditionalPrayersService._internal();
  factory TraditionalPrayersService() => _instance;
  TraditionalPrayersService._internal();

  Map<String, dynamic>? _prayersData;

  /// Carga las oraciones desde el archivo JSON
  Future<void> loadPrayers() async {
    if (_prayersData != null) return;
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/oraciones/oraciones.json',
      );
      _prayersData = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error loading traditional prayers: $e');
    }
  }

  /// Obtiene las categorías disponibles para una religión
  List<String> getCategories(String religion) {
    if (_prayersData == null) return [];
    final religionData =
        _prayersData![religion == 'general' ? 'cristiana' : religion]
            as Map<String, dynamic>?;
    if (religionData == null) return [];
    return religionData.keys.toList();
  }

  /// Obtiene las oraciones de una categoría específica
  Map<String, dynamic> getPrayersByCategory(String religion, String category) {
    if (_prayersData == null) return {};
    final religionData =
        _prayersData![religion == 'general' ? 'cristiana' : religion]
            as Map<String, dynamic>?;
    if (religionData == null) return {};
    final categoryData = religionData[category] as Map<String, dynamic>?;
    if (categoryData == null) return {};
    return Map<String, dynamic>.from(categoryData);
  }

  /// Obtiene una oración específica
  Map<String, dynamic>? getPrayer(
    String religion,
    String category,
    String prayerKey,
  ) {
    final categoryPrayers = getPrayersByCategory(religion, category);
    final prayer = categoryPrayers[prayerKey] as Map<String, dynamic>?;
    if (prayer == null) return null;
    return {
      ...prayer,
      'provenance': ContentProvenance.forBundledPrayer(
        prayer['titulo'] as String? ?? prayerKey,
      ),
    };
  }

  /// Biblical quotations are resolved from one edition, never from loose copies.
  Future<Map<String, dynamic>?> readPrayer(
    String religion,
    String category,
    String prayerKey, {
    Future<List<Verse>> Function(String, int)? chapterLoader,
  }) async {
    await loadPrayers();
    final prayer = getPrayer(religion, category, prayerKey);
    if (prayer == null) return null;
    final passages = biblicalPrayerPassages(religion, prayerKey);
    if (passages.isEmpty) return prayer;
    final load = chapterLoader ?? BibleDb.instance.getChapter;
    final blocks = <String>[];
    for (final passage in passages) {
      final chapter = await load(passage.book, passage.chapter);
      final verses =
          chapter
              .where((v) => v.verse >= passage.first && v.verse <= passage.last)
              .toList()
            ..sort((a, b) => a.verse.compareTo(b.verse));
      if (verses.length != passage.last - passage.first + 1 ||
          List.generate(
            verses.length,
            (i) => passage.first + i,
          ).any((n) => !verses.any((v) => v.verse == n))) {
        throw StateError(
          'No está disponible el pasaje completo: ${passage.reference}',
        );
      }
      blocks.add(
        '${passage.reference}\n${verses.map((v) => '${v.verse}. ${v.text}').join('\n')}',
      );
    }
    return {
      ...prayer,
      'texto': blocks.join('\n\n'),
      'provenance': ContentProvenance.bible,
    };
  }

  /// Obtiene el nombre de la categoría en formato legible
  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'basicas':
        return 'Oraciones Básicas';
      case 'arcangeles':
        return 'Arcángeles';
      case 'del_dia':
        return 'Oraciones del Día';
      case 'biblicas':
        return 'Oraciones Bíblicas';
      case 'promesas':
        return 'Promesas Bíblicas';
      case 'otras':
        return 'Otras Oraciones';
      default:
        return category;
    }
  }

  /// Obtiene los pasos de un día específico de la Novena
  Map<String, dynamic>? getNovenaDay(int day) {
    if (_prayersData == null) return null;
    final novenaData = _prayersData!['novena'] as Map<String, dynamic>?;
    if (novenaData == null) return null;
    final dayKey = 'dia_$day';
    return novenaData[dayKey] as Map<String, dynamic>?;
  }

  /// Obtiene un paso específico de un día de la Novena
  Map<String, dynamic>? getNovenaStep(int day, int step) {
    final dayData = getNovenaDay(day);
    if (dayData == null) return null;
    final stepKey = 'paso_$step';
    return dayData[stepKey] as Map<String, dynamic>?;
  }

  /// Obtiene el número total de pasos de un día de la Novena
  int getNovenaDayStepCount(int day) {
    final dayData = getNovenaDay(day);
    if (dayData == null) return 0;
    return dayData.length;
  }
}
