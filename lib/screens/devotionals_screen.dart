import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/devotionals_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../models/devotional.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/main_card.dart';
import '../theme/app_theme.dart';

/// Pantalla de devocionales diarios
class DevotionalsScreen extends StatefulWidget {
  const DevotionalsScreen({super.key});

  @override
  State<DevotionalsScreen> createState() => _DevotionalsScreenState();
}

class _DevotionalsScreenState extends State<DevotionalsScreen> {
  final DevotionalsService _service = DevotionalsService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  bool _isLoading = true;
  bool _showTodayOnly = false;

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
    await _service.loadDevotionals();
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

    // Actualizar estado de anuncios
    final storage = StorageService();
    final adsRemovedNow = storage.getAdsRemoved();
    if (adsRemovedNow && !_adsRemoved) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _adsRemoved = true;
    }

    final devotionals = _showTodayOnly
        ? [_service.getTodayDevotional()].whereType<Devotional>().toList()
        : _service.getAllDevotionals();

    return AppScaffold(
      title: 'Devocionales Diarios',
      actions: [
        IconButton(
          icon: Icon(_showTodayOnly ? Icons.list : Icons.today),
          onPressed: () => setState(() => _showTodayOnly = !_showTodayOnly),
          tooltip: _showTodayOnly ? 'Ver todos' : 'Ver solo hoy',
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : devotionals.isEmpty
                    ? EmptyState(
                        title: 'No hay devocionales disponibles',
                        message: 'Intenta recargar más tarde',
                        icon: Icons.book_outlined,
                        onAction: _loadData,
                        actionLabel: 'Recargar',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: devotionals.length,
                        itemBuilder: (context, index) {
                          final devotional = devotionals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: MainCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    devotional.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(
                                        color: colorScheme.tertiary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          devotional.verse,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            height: 1.6,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          devotional.verseReference,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.tertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    devotional.reflection,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.6,
                                    ),
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

