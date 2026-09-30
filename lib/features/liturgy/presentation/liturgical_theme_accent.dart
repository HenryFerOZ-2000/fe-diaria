import 'package:flutter/material.dart';

import '../../../faith/faith_tradition.dart';
import '../../../services/storage_service.dart';
import '../application/calendar_region_resolver.dart';
import '../application/liturgical_accent_controller.dart';
import '../application/liturgy_service.dart';
import '../data/asset_liturgy_repository.dart';
import '../domain/liturgical_day.dart';
import 'liturgical_palette.dart';

/// Traduce el color litúrgico al acento del tema (`null` = pan de oro).
Color? liturgicalThemeAccent(LiturgicalColor? color, Brightness brightness) =>
    color == null ? null : LiturgicalPalette.accent(color, brightness);

/// Controlador del acento conectado al almacenamiento real de la app.
LiturgicalAccentController createAppLiturgicalAccentController({
  StorageService? storage,
}) {
  final store = storage ?? StorageService();
  // Un solo repositorio para reutilizar su caché entre recargas.
  final repository = AssetLiturgyRepository();
  final resolver = CalendarRegionResolver(
    readStoredCountry: store.getCatholicCalendarCountry,
  );
  return LiturgicalAccentController(
    readTradition: () => faithTraditionFromStorageString(
      store.getValidatedTraditionalPrayersReligion(),
    ),
    traditionChanges: store.faithPreferencesListenable(),
    loaderFor: (tradition) => LiturgyService(
      repository: repository,
      selection: resolver.resolve(tradition).selection,
    ),
  );
}
