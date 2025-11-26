import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ContentValidator {
  static Future<void> validateAssets() async {
    try {
      await _validatePrayers();
      await _validateVerses();
    } catch (e) {
      debugPrint('Content validation error: $e');
    }
  }

  static Future<void> _validatePrayers() async {
    await _validateListJson(
      path: 'assets/prayers/morning_365.json',
      expectedMin: 365,
      itemPath: 'text',
      label: 'morning_365',
    );
    await _validateListJson(
      path: 'assets/prayers/night_365.json',
      expectedMin: 365,
      itemPath: 'text',
      label: 'night_365',
    );
  }

  static Future<void> _validateVerses() async {
    const monthFiles = [
      'assets/verses/january.json',
      'assets/verses/february.json',
      'assets/verses/march.json',
      'assets/verses/april.json',
      'assets/verses/may.json',
      'assets/verses/june.json',
      'assets/verses/july.json',
      'assets/verses/august.json',
      'assets/verses/september.json',
      'assets/verses/october.json',
      'assets/verses/november.json',
      'assets/verses/december.json',
    ];
    int total = 0;
    for (final path in monthFiles) {
      try {
        final raw = await rootBundle.loadString(path);
        final data = json.decode(raw) as List<dynamic>;
        total += data.length;
      } catch (e) {
        debugPrint('Validation: could not read $path: $e');
      }
    }
    if (total < 365) {
      debugPrint('Validation: verses total $total < 365 (will normalize by cycling)');
    } else if (total > 365) {
      debugPrint('Validation: verses total $total > 365 (will truncate to 365)');
    } else {
      debugPrint('Validation: verses total OK = 365');
    }
  }

  static Future<void> _validateListJson({
    required String path,
    required int expectedMin,
    required String itemPath,
    required String label,
  }) async {
    try {
      final raw = await rootBundle.loadString(path);
      final list = json.decode(raw) as List<dynamic>;
      if (list.length < expectedMin) {
        debugPrint('Validation: $label has only ${list.length} items (< $expectedMin). Will cycle at runtime.');
      }
      // spot check first item
      if (list.isNotEmpty) {
        final first = list.first;
        if (first is Map && !first.containsKey(itemPath)) {
          debugPrint('Validation: $label first item missing "$itemPath" field.');
        }
      }
    } catch (e) {
      debugPrint('Validation: could not read $label at $path: $e');
    }
  }

}


