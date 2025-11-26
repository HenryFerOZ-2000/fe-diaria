import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

/// Servicio de compra única para remover anuncios.
/// Guarda permanentemente el estado en almacenamiento local.
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  static const String removeAdsProductId = 'remove_ads';

  final InAppPurchase _iap = InAppPurchase.instance;
  final StorageService _storage = StorageService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    _subscription ??= _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () {
      _subscription?.cancel();
      _subscription = null;
    }, onError: (Object error) {
      debugPrint('IAP error: $error');
    });
  }

  Future<bool> get isAdsRemoved async {
    return _storage.getAdsRemoved();
  }

  Future<void> restorePurchases() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return;
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
  }

  Future<void> buyRemoveAds() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return;
      final bool already = _storage.getAdsRemoved();
      if (already) return;

      const Set<String> ids = {removeAdsProductId};
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(ids);
      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        debugPrint('Product not found: $ids');
        return;
      }
      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('buyRemoveAds error: $e');
    }
  }

  Future<void> _onPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID == removeAdsProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _storage.setAdsRemoved(true);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }
}


