import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Banner de AdMob fijo para la pantalla principal (Android).
/// Carga el banner, muestra [AdWidget] y hace [dispose] al desmontar.
class AdBanner extends StatefulWidget {
  /// Si false, no se muestra ni se carga el anuncio (p. ej. cuando el usuario removió anuncios).
  final bool visible;

  const AdBanner({super.key, this.visible = true});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  static const String _androidBannerUnitId =
      'ca-app-pub-3562621553800544/3701186528';

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _loadAd();
    }
  }

  @override
  void didUpdateWidget(AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _loadAd();
    } else if (!widget.visible && oldWidget.visible) {
      _disposeAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _androidBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('AdBanner failed to load: $error');
        },
      ),
    );
    _bannerAd?.load();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    if (!_isLoaded || _bannerAd == null) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: AdSize.banner.height.toDouble(),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
