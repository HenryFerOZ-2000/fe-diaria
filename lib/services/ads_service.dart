import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // IDs de prueba de Google AdMob
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdReady => _isBannerAdReady;

  void loadBannerAd({
    AdSize? adSize,
    required void Function(BannerAd) onAdLoaded,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    _bannerAd = BannerAd(
      adUnitId: _testBannerAdUnitId,
      size: adSize ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdReady = false;
          ad.dispose();
          onAdFailedToLoad(error);
        },
        onAdOpened: (_) {},
        onAdClosed: (_) {},
      ),
    );

    _bannerAd?.load();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }

  Future<InterstitialAd?> loadInterstitialAd({
    required VoidCallback onAdDismissed,
  }) async {
    InterstitialAd? interstitialAd;

    await InterstitialAd.load(
      adUnitId: _testInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (error) {
          interstitialAd = null;
        },
      ),
    );

    return interstitialAd;
  }
}

