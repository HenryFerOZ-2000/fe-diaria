import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/prayers_by_intention_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';

/// Pantalla de peticiones especiales
class PrayersByIntentionScreen extends StatefulWidget {
  const PrayersByIntentionScreen({super.key});

  @override
  State<PrayersByIntentionScreen> createState() => _PrayersByIntentionScreenState();
}

class _PrayersByIntentionScreenState extends State<PrayersByIntentionScreen> {
  final PrayersByIntentionService _service = PrayersByIntentionService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  bool _isLoading = true;
  String? _selectedIntention;

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
    setState(() {
      _isLoading = false;
      _selectedIntention = _service.getAvailableIntentions().firstOrNull;
    });
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

    final intentions = _service.getAvailableIntentions();
    final prayers = _selectedIntention != null
        ? [_service.getPrayerForIntention(_selectedIntention!)].whereType<Map<String, dynamic>>().toList()
        : _service.getAllPrayers();

    return AppScaffold(
      title: 'Peticiones Especiales',
      body: Column(
        children: [
          // Grid de intenciones
          if (intentions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: intentions.map((intention) {
                  final isSelected = _selectedIntention == intention;
                  return FilterChip(
                    label: Text(intention),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedIntention = selected ? intention : null);
                    },
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : prayers.isEmpty
                    ? EmptyState(
                        title: 'No hay oraciones disponibles',
                        message: 'Intenta recargar más tarde',
                        icon: Icons.healing_outlined,
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
                              icon: Icons.healing_rounded,
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

