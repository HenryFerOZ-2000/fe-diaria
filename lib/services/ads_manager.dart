import 'package:flutter/material.dart';
import 'ads_service.dart';
import 'storage_service.dart';

/// Gestor central de anuncios: controla reglas de frecuencia y anti-molestia.
class AdsManager {
  static final AdsManager _instance = AdsManager._internal();
  factory AdsManager() => _instance;
  AdsManager._internal();

  final AdsService _adsService = AdsService();
  final StorageService _storage = StorageService();

  bool _isShowingInterstitial = false;

  bool get adsRemoved => _storage.getAdsRemoved();

  /// Mostrar interstitial al ingresar a “Oraciones para…”.
  /// No bloquea la navegación; intenta cargar y mostrar en segundo plano.
  void tryShowCategoryEntryInterstitial({VoidCallback? onDismissed}) async {
    if (adsRemoved) return;
    if (_isShowingInterstitial) return;
    // Anti-molestia: no en lectura ni entrada de texto. La categoría es segura.
    final interstitial = await _adsService.loadInterstitialAd(
      onAdDismissed: () {
        _isShowingInterstitial = false;
        if (onDismissed != null) onDismissed();
      },
    );
    if (interstitial != null) {
      _isShowingInterstitial = true;
      interstitial.show();
    }
  }

  /// Interstitial cada 12 horas (máximo dos por día).
  /// Se invoca al entrar a la app (pantallas principales), pero evita pantallas sensibles.
  Future<void> maybeShowDailyInterstitial({
    required BuildContext context,
    bool isSensitiveContext = false,
  }) async {
    if (adsRemoved) return;
    if (isSensitiveContext) return;
    if (_isShowingInterstitial) return;

    // Máximo 2 por día
    final shownToday = _storage.getDailyInterstitialCount();
    if (shownToday >= 2) return;

    // Lógica de mañana/noche según hora local
    final now = DateTime.now();
    final isMorning = now.hour >= 5 && now.hour < 18;
    final morningShown = _storage.getMorningInterstitialShownToday();
    final nightShown = _storage.getNightInterstitialShownToday();

    if (isMorning && morningShown) return;
    if (!isMorning && nightShown) return;

    final ad = await _adsService.loadInterstitialAd(
      onAdDismissed: () async {
        _isShowingInterstitial = false;
      },
    );
    if (ad == null) return;

    _isShowingInterstitial = true;
    ad.show();

    // Marcar contadores y sellos de tiempo
    await _storage.incrementDailyInterstitialCount();
    if (isMorning) {
      await _storage.markMorningInterstitialShown();
    } else {
      await _storage.markNightInterstitialShown();
    }
  }
}


