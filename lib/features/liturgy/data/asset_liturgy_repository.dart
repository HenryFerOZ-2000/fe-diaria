import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/calendar_selection.dart';
import '../domain/liturgical_day.dart';
import '../domain/liturgical_source.dart';
import 'liturgy_repository.dart';

typedef AssetLoader = Future<String> Function(String path);

final class AssetLiturgyRepository implements LiturgyRepository {
  AssetLiturgyRepository({
    AssetLoader? loadAsset,
    Map<String, String>? verifiedCountryAssets,
  }) : _loadAsset = loadAsset ?? rootBundle.loadString,
       _verifiedCountryAssetsOverride = verifiedCountryAssets;

  static const baseAsset = 'assets/liturgy/general_roman_es_2025_2035.json';
  static const manifestAsset = 'assets/liturgy/manifest.json';

  final AssetLoader _loadAsset;
  final Map<String, String>? _verifiedCountryAssetsOverride;
  final Map<String, Future<Map<String, LiturgicalDay>>> _calendarCache = {};
  Future<Map<String, String>>? _manifestCache;

  @override
  Future<LiturgicalDay?> forDate(
    DateTime date, {
    required CalendarSelection selection,
  }) async {
    final key = _dateKey(date);
    final base = await _loadCalendar(baseAsset);
    final countryAssets = await _countryAssets();
    final countryAsset = selection.countryCode == null
        ? null
        : countryAssets[selection.countryCode];
    if (countryAsset == null) return base[key];

    try {
      final country = await _loadCalendar(countryAsset);
      return country[key] ?? base[key];
    } on Object catch (error) {
      debugPrint('[AssetLiturgyRepository] País no disponible: $error');
      return base[key];
    }
  }

  Future<Map<String, String>> _countryAssets() {
    final override = _verifiedCountryAssetsOverride;
    if (override != null) return Future.value(override);
    return _manifestCache ??= _loadManifest();
  }

  Future<Map<String, String>> _loadManifest() async {
    try {
      final raw = jsonDecode(await _loadAsset(manifestAsset));
      if (raw is! Map<String, dynamic> || raw['schemaVersion'] != 1) {
        throw const FormatException('Manifiesto litúrgico inválido');
      }
      if (raw['base'] != baseAsset || raw['verifiedCountries'] is! Map) {
        throw const FormatException('Rutas del manifiesto litúrgico inválidas');
      }
      final countries = <String, String>{};
      for (final entry in (raw['verifiedCountries'] as Map).entries) {
        final country = entry.key;
        final path = entry.value;
        if (country is! String ||
            !RegExp(r'^[A-Z]{2}$').hasMatch(country) ||
            path is! String ||
            !path.startsWith('assets/liturgy/countries/')) {
          throw const FormatException('Paquete nacional no permitido');
        }
        countries[country] = path;
      }
      return Map.unmodifiable(countries);
    } on Object catch (error) {
      debugPrint('[AssetLiturgyRepository] Manifiesto no disponible: $error');
      return const {};
    }
  }

  Future<Map<String, LiturgicalDay>> _loadCalendar(String path) {
    return _calendarCache.putIfAbsent(path, () async {
      final decoded = jsonDecode(await _loadAsset(path));
      if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
        throw const FormatException('Calendario litúrgico inválido');
      }
      final rawSource = decoded['source'];
      final rawDays = decoded['days'];
      if (rawSource is! Map || rawDays is! Map) {
        throw const FormatException('Fuente o días litúrgicos inválidos');
      }
      final source = LiturgicalSource.fromJson(
        Map<String, dynamic>.from(rawSource),
      );
      final days = <String, LiturgicalDay>{};
      for (final entry in rawDays.entries) {
        if (entry.key is! String || entry.value is! Map) {
          throw const FormatException('Entrada litúrgica inválida');
        }
        final day = LiturgicalDay.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
          source: source,
        );
        if (_dateKey(day.date) != entry.key) {
          throw const FormatException('La clave no coincide con la fecha');
        }
        days[entry.key as String] = day;
      }
      return Map.unmodifiable(days);
    });
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
