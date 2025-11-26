import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/prayers_by_emotion_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/main_card.dart';
import '../theme/app_theme.dart';

/// Pantalla que muestra oración y versículo para una emoción específica
class EmotionDetailScreen extends StatefulWidget {
  final String emotion;
  final String emotionName;

  const EmotionDetailScreen({
    super.key,
    required this.emotion,
    required this.emotionName,
  });

  @override
  State<EmotionDetailScreen> createState() => _EmotionDetailScreenState();
}

class _EmotionDetailScreenState extends State<EmotionDetailScreen> {
  final PrayersByEmotionService _service = PrayersByEmotionService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  bool _isLoading = true;
  Map<String, dynamic>? _prayerData;

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
    final prayer = _service.getPrayerForEmotion(widget.emotion);
    setState(() {
      _prayerData = prayer;
      _isLoading = false;
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

    return AppScaffold(
      title: 'Dios está contigo',
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _prayerData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: AppSpacing.md),
                      Text('No se pudo cargar la oración', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      CustomButton(
                        text: 'Reintentar',
                        icon: Icons.refresh,
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título principal
                            Text(
                              'Dios está contigo en este momento de ${widget.emotionName.toLowerCase()}',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Oración
                            PrayerCard(
                              title: _prayerData!['title'] as String,
                              text: _prayerData!['text'] as String,
                              icon: Icons.favorite_rounded,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Versículo motivador
                            if (_prayerData!['verse'] != null)
                              MainCard(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                backgroundColor: colorScheme.tertiary.withOpacity(0.1),
                                border: Border.all(
                                  color: colorScheme.tertiary.withOpacity(0.3),
                                  width: 2,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.book_rounded,
                                          color: colorScheme.tertiary,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          'Versículo para ti',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: colorScheme.tertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      _prayerData!['verse'] as String,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontSize: 18,
                                        height: 1.7,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    if (_prayerData!['verseReference'] != null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        _prayerData!['verseReference'] as String,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.tertiary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CustomButton(
                        text: 'Regresar',
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.of(context).pop(),
                        width: double.infinity,
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

