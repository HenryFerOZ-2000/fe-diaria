import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/psalms_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';

/// Pantalla de salmos por categoría
class PsalmsScreen extends StatefulWidget {
  const PsalmsScreen({super.key});

  @override
  State<PsalmsScreen> createState() => _PsalmsScreenState();
}

class _PsalmsScreenState extends State<PsalmsScreen> {
  final PsalmsService _service = PsalmsService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  bool _isLoading = true;
  String? _selectedCategory;

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
    await _service.loadPsalms();
    setState(() {
      _isLoading = false;
      _selectedCategory = _service.getCategories().firstOrNull;
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

    final categories = _service.getCategories();
    final psalms = _selectedCategory != null
        ? _service.getPsalmsByCategory(_selectedCategory!)
        : _service.getAllPsalms();

    return AppScaffold(
      title: 'Salmos por Categoría',
      body: Column(
        children: [
          // Filtro de categorías
          if (categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = selected ? category : null);
                      },
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : psalms.isEmpty
                    ? EmptyState(
                        title: 'No hay salmos disponibles',
                        message: 'Intenta recargar más tarde',
                        icon: Icons.library_books_outlined,
                        onAction: _loadData,
                        actionLabel: 'Recargar',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: psalms.length,
                        itemBuilder: (context, index) {
                          final psalm = psalms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: PrayerCard(
                              title: psalm.title,
                              text: psalm.text,
                              reference: psalm.reference,
                              icon: Icons.library_books_rounded,
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

