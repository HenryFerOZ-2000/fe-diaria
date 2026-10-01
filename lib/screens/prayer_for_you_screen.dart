import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/app_provider.dart';
import '../services/personalization_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../models/verse.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_reading_experience.dart';
import 'package:verbum/design_system/design_system.dart';

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
        final personalizedPrayerText = personalizationService
            .generatePersonalizedPrayer(emotion, userName);

        // Obtener versículo personalizado (si hay emoción)
        final verse = provider.todayVerse;
        final p = context.palette;

        return AppScaffold(
          title: 'Oración para ti',
          centerTitle: false,
          actions: [
            VIconButton(
              icon: VerbumIcons.arrowClockwise,
              semanticLabel: 'Actualizar',
              onPressed: () async {
                await provider.loadTodayVerse();
                await provider.loadTodayPrayers();
              },
            ),
          ],
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    VerbumSpace.gutter,
                    VerbumSpace.xs,
                    VerbumSpace.gutter,
                    VerbumSpace.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Acción para cambiar emoción
                      VActionTile(
                        icon: VerbumIcons.smiley,
                        title: '¿Cómo te sientes ahora?',
                        subtitle: 'Elige otra emoción para tu oración',
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed('/emotion-selection');
                        },
                      ),
                      const SizedBox(height: VerbumSpace.lg),

                      // Oración personalizada
                      _buildPrayerCard(
                        context: context,
                        prayerText: personalizedPrayerText,
                        userName: userName,
                      ),

                      const SizedBox(height: VerbumSpace.md),

                      // Versículo relacionado
                      if (verse != null)
                        _buildVerseCard(context: context, verse: verse),
                    ],
                  ),
                ),
              ),
              // Banner Ad fijo en la parte inferior
              if (!_adsRemoved)
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: _bannerAd != null
                      ? _bannerAd!.size.height.toDouble()
                      : 50,
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border(top: BorderSide(color: p.line)),
                  ),
                  child: _bannerAd != null
                      ? AdWidget(ad: _bannerAd!)
                      : SizedBox(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.rubric,
                            ),
                          ),
                        ),
                ),
              // Botón de regreso al inicio
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  VerbumSpace.sm,
                  VerbumSpace.gutter,
                  VerbumSpace.md,
                ),
                child: VButton(
                  label: 'Regresar al inicio',
                  icon: VerbumIcons.house,
                  iconLeading: true,
                  expanded: true,
                  onPressed: () {
                    Navigator.of(context).pushNamed('/home');
                  },
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
    final p = context.palette;
    final type = context.type;
    final title = userName.isNotEmpty
        ? 'Oración para $userName'
        : 'Tu oración personalizada';

    return VSurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PrayerTextReadingScreen(
            provenance: ContentProvenance.aiGenerated,
            title: title,
            text: prayerText,
            category: 'Oración para ti',
          ),
        ),
      ),
      padding: const EdgeInsets.all(VerbumSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VerbumSpace.sm),
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(VerbumRadius.control),
                ),
                child: VIcon(
                  VerbumIcons.heart,
                  weight: VIconWeight.duotone,
                  color: p.rubric,
                  size: 26,
                ),
              ),
              const SizedBox(width: VerbumSpace.sm),
              Expanded(child: Text(title, style: type.heading)),
            ],
          ),
          const SizedBox(height: VerbumSpace.md),
          Text(prayerText, style: type.scripture),
        ],
      ),
    );
  }

  Widget _buildVerseCard({
    required BuildContext context,
    required Verse verse,
  }) {
    final p = context.palette;
    final type = context.type;

    return VSurfaceCard(
      tone: VSurfaceTone.accent,
      padding: const EdgeInsets.all(VerbumSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VIcon(
                VerbumIcons.bookOpenText,
                weight: VIconWeight.duotone,
                color: p.rubric,
                size: 22,
              ),
              const SizedBox(width: VerbumSpace.xs),
              Text('Versículo para ti', style: type.rubric),
            ],
          ),
          const SizedBox(height: VerbumSpace.sm),
          Text(verse.text, style: type.scriptureLarge),
          const SizedBox(height: VerbumSpace.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(verse.reference, style: type.citation),
          ),
        ],
      ),
    );
  }
}
