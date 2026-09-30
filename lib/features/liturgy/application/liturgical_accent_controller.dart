import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../faith/faith_tradition.dart';
import '../../../faith/tradition_capabilities.dart';
import '../domain/liturgical_day.dart';
import 'liturgy_service.dart';

/// Color litúrgico que debe teñir la interfaz, o `null` para el acento
/// neutro (pan de oro).
///
/// Solo las tradiciones con liturgia diaria siguen el calendario; el resto
/// mantiene un acento fijo para no imponer un calendario que no usan.
LiturgicalColor? resolveLiturgicalAccent({
  required FaithTradition tradition,
  required LiturgicalDay? day,
}) {
  if (!TraditionCapabilities.forTradition(tradition).showDailyLiturgy) {
    return null;
  }
  final colors = day?.primary.colors;
  if (colors == null || colors.isEmpty) return null;
  return colors.first;
}

/// Mantiene actualizado el color litúrgico del día para el tema de la app.
///
/// Se recalcula al cambiar la tradición ([traditionChanges]) y a medianoche.
class LiturgicalAccentController extends ChangeNotifier {
  LiturgicalAccentController({
    required this.readTradition,
    required this.loaderFor,
    this.traditionChanges,
  }) {
    traditionChanges?.addListener(refresh);
  }

  final FaithTradition Function() readTradition;
  final DailyLiturgyLoader Function(FaithTradition tradition) loaderFor;
  final Listenable? traditionChanges;
  Timer? _midnight;
  int _generation = 0;
  bool _disposed = false;

  LiturgicalColor? _color;
  LiturgicalColor? get color => _color;

  Future<void> refresh() async {
    final generation = ++_generation;
    final tradition = readTradition();
    _midnight?.cancel();

    if (!TraditionCapabilities.forTradition(tradition).showDailyLiturgy) {
      _set(null);
      return;
    }

    final loader = loaderFor(tradition);
    LiturgicalDay? day;
    try {
      day = await loader.today();
    } on Object catch (error) {
      debugPrint('[LiturgicalAccentController] $error');
    }
    // Una recarga más reciente (p. ej. cambio de tradición) ya tomó el relevo.
    if (_disposed || generation != _generation) return;

    _set(resolveLiturgicalAccent(tradition: tradition, day: day));
    _midnight = Timer(loader.untilNextDay(), refresh);
  }

  void _set(LiturgicalColor? value) {
    if (_disposed || value == _color) return;
    _color = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _midnight?.cancel();
    traditionChanges?.removeListener(refresh);
    super.dispose();
  }
}
