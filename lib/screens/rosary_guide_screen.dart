import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/rosary_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/main_card.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';

/// Pantalla de guía del rosario
class RosaryGuideScreen extends StatefulWidget {
  const RosaryGuideScreen({super.key});

  @override
  State<RosaryGuideScreen> createState() => _RosaryGuideScreenState();
}

class _RosaryGuideScreenState extends State<RosaryGuideScreen> {
  final RosaryService _service = RosaryService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  bool _isLoading = true;
  int _currentStep = 0;

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
    await _service.loadGuide();
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
    final guide = _service.getGuide();
    final todayMysteries = _service.getTodayMysteries();
    final steps = _service.getAllSteps();

    return AppScaffold(
      title: 'Guía del Rosario',
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : guide == null
              ? Center(child: Text('No se pudo cargar la guía', style: theme.textTheme.bodyLarge))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MainCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    guide.title,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    guide.description,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (todayMysteries != null) ...[
                              Text(
                                'Misterios de Hoy (${todayMysteries.day})',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              MainCard(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todayMysteries.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    ...todayMysteries.mysteries.asMap().entries.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${entry.key + 1}.',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              child: Text(
                                                entry.value,
                                                style: theme.textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Pasos del Rosario',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (steps.isNotEmpty && _currentStep < steps.length)
                              MainCard(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      steps[_currentStep].title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    if (steps[_currentStep].repetitions != null) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Repetir ${steps[_currentStep].repetitions} veces',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      steps[_currentStep].prayer,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        height: 1.7,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Row(
                                      children: [
                                        if (_currentStep > 0)
                                          Expanded(
                                            child: CustomButton(
                                              text: 'Anterior',
                                              icon: Icons.arrow_back,
                                              onPressed: () {
                                                setState(() => _currentStep--);
                                              },
                                            ),
                                          ),
                                        if (_currentStep > 0) const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: CustomButton(
                                            text: _currentStep < steps.length - 1 ? 'Siguiente' : 'Finalizar',
                                            icon: Icons.arrow_forward,
                                            onPressed: _currentStep < steps.length - 1
                                                ? () {
                                                    setState(() => _currentStep++);
                                                  }
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
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

