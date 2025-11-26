import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/app_provider.dart';
import '../services/personalization_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../models/verse.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/main_card.dart';
import '../theme/app_theme.dart';

/// Pantalla dedicada "Oración para ti" - Mostrando oración y versículo personalizados
class PrayerForYouScreen extends StatefulWidget {
  const PrayerForYouScreen({super.key});

  @override
  State<PrayerForYouScreen> createState() => _PrayerForYouScreenState();
}

class _PrayerForYouScreenState extends State<PrayerForYouScreen> {
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;

  @override
  void initState() {
    super.initState();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    if (_adsRemoved) return;
    
    _adsService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        if (mounted && !_adsRemoved) {
          setState(() {
            _bannerAd = ad;
          });
        } else {
          ad.dispose();
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Failed to load banner ad: $error');
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Actualizar estado de anuncios removidos
    final storage = StorageService();
    final adsRemovedNow = storage.getAdsRemoved();
    if (adsRemovedNow && !_adsRemoved) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _adsRemoved = true;
    } else if (!adsRemovedNow && _adsRemoved) {
      _adsRemoved = false;
      _loadBannerAd();
    } else if (!adsRemovedNow && _bannerAd == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_adsRemoved && _bannerAd == null) {
          _loadBannerAd();
        }
      });
    }

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final personalizationService = PersonalizationService();
        final userName = personalizationService.getUserName();
        final emotion = personalizationService.getUserEmotion();
        
        // Generar oración personalizada
        final personalizedPrayerText = personalizationService.generatePersonalizedPrayer(
          emotion,
          userName,
        );
        
        // Obtener versículo personalizado (si hay emoción)
        final verse = provider.todayVerse;
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AppScaffold(
          title: 'Oración para ti',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await provider.loadTodayVerse();
                await provider.loadTodayPrayers();
              },
              tooltip: 'Actualizar',
            ),
          ],
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botón grande para cambiar emoción
                      CustomButton(
                        text: '¿Cómo te sientes ahora?',
                        icon: Icons.emoji_emotions_outlined,
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/emotion-selection');
                        },
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        fontSize: 18,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Oración personalizada
                      _buildPrayerCard(
                        context: context,
                        prayerText: personalizedPrayerText,
                        userName: userName,
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Versículo relacionado
                      if (verse != null)
                        _buildVerseCard(
                          context: context,
                          verse: verse,
                        ),
                    ],
                  ),
                ),
              ),
              // Banner Ad fijo en la parte inferior
              if (!_adsRemoved)
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: _bannerAd != null ? _bannerAd!.size.height.toDouble() : 50,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surface
                        : AppColors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: _bannerAd != null
                      ? AdWidget(ad: _bannerAd!)
                      : const SizedBox(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                ),
              // Botón de regreso al inicio
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CustomButton(
                  text: 'Regresar al inicio',
                  icon: Icons.home,
                  onPressed: () {
                    Navigator.of(context).pushNamed('/home');
                  },
                  width: double.infinity,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrayerCard({
    required BuildContext context,
    required String prayerText,
    required String userName,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MainCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
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
                      Icons.favorite,
                      color: colorScheme.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      userName.isNotEmpty 
                          ? 'Oración para $userName'
                          : 'Tu Oración Personalizada',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                prayerText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  height: 1.8,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard({
    required BuildContext context,
    required Verse verse,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MainCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: colorScheme.tertiary.withOpacity(0.1),
      border: Border.all(
        color: colorScheme.tertiary.withOpacity(0.3),
        width: 2,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.06,
              child: Icon(
                Icons.book,
                size: 140,
                color: colorScheme.tertiary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.book,
                      color: colorScheme.tertiary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Versículo para ti',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                verse.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  height: 1.8,
                  fontStyle: FontStyle.italic,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                verse.reference,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

