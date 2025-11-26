import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/night_prayers_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';

/// Pantalla de oraciones para dormir
class NightPrayersScreen extends StatefulWidget {
  const NightPrayersScreen({super.key});

  @override
  State<NightPrayersScreen> createState() => _NightPrayersScreenState();
}

class _NightPrayersScreenState extends State<NightPrayersScreen> {
  final NightPrayersService _service = NightPrayersService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _service.loadPrayers();
    setState(() => _isLoading = false);
  }

  void _loadBannerAd() {
    if (_adsRemoved) return;
    _adsService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        if (mounted && !_adsRemoved) {
          setState(() => _bannerAd = ad);
        } else {
          ad.dispose();
        }
      },
      onAdFailedToLoad: (error) => debugPrint('Failed to load banner ad: $error'),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final prayers = _service.getAllPrayers();

    return AppScaffold(
      title: 'Oraciones para Dormir',
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : prayers.isEmpty
                    ? EmptyState(
                        title: 'No hay oraciones disponibles',
                        message: 'Intenta recargar más tarde',
                        icon: Icons.bedtime_outlined,
                        onAction: _loadData,
                        actionLabel: 'Recargar',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: prayers.length,
                        itemBuilder: (context, index) {
                          final prayer = prayers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: PrayerCard(
                              title: prayer['title'] as String,
                              text: prayer['text'] as String,
                              icon: Icons.bedtime_rounded,
                              accentColor: colorScheme.tertiary,
                            ),
                          );
                        },
                      ),
          ),
          if (!_adsRemoved)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: _bannerAd != null ? _bannerAd!.size.height.toDouble() : 50,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : AppColors.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1),
                ),
              ),
              child: _bannerAd != null
                  ? AdWidget(ad: _bannerAd!)
                  : const SizedBox(
                      height: 50,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
            ),
        ],
      ),
    );
  }
}

