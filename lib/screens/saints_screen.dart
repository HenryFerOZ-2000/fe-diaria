import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/saints_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/main_card.dart';
import '../theme/app_theme.dart';

/// Pantalla de santos del día
class SaintsScreen extends StatefulWidget {
  const SaintsScreen({super.key});

  @override
  State<SaintsScreen> createState() => _SaintsScreenState();
}

class _SaintsScreenState extends State<SaintsScreen> {
  final SaintsService _service = SaintsService();
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
    await _service.loadSaints();
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
    final saints = _service.getAllSaints();

    return AppScaffold(
      title: 'Santos del Día',
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : saints.isEmpty
                    ? EmptyState(
                        title: 'No hay santos disponibles',
                        message: 'Intenta recargar más tarde',
                        icon: Icons.auto_stories_outlined,
                        onAction: _loadData,
                        actionLabel: 'Recargar',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: saints.length,
                        itemBuilder: (context, index) {
                          final saint = saints[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: MainCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        child: Icon(
                                          Icons.auto_stories_rounded,
                                          color: colorScheme.secondary,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              saint['name'] as String,
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Fiesta: ${saint['feastDay'] as String}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    saint['description'] as String,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  PrayerCard(
                                    title: 'Oración',
                                    text: saint['prayer'] as String,
                                    icon: Icons.favorite_rounded,
                                    accentColor: colorScheme.secondary,
                                  ),
                                ],
                              ),
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

