import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/prayers_by_emotion_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_card.dart';
import 'package:verbum/design_system/design_system.dart';

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
      onAdFailedToLoad: (error) =>
          debugPrint('Failed to load banner ad: $error'),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    return AppScaffold(
      title: 'Dios está contigo',
      centerTitle: false,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: p.rubric))
          : _prayerData == null
          ? Center(
              child: VEmptyState(
                icon: VerbumIcons.warningCircle,
                title: 'No se pudo cargar la oración',
                actionLabel: 'Reintentar',
                onAction: _loadData,
              ),
            )
          : Column(
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
                        // Título principal
                        Semantics(
                          header: true,
                          child: Text(
                            'Dios está contigo en este momento de ${widget.emotionName.toLowerCase()}',
                            style: type.title,
                          ),
                        ),
                        const SizedBox(height: VerbumSpace.lg),
                        // Oración
                        PrayerCard(
                          provenance: ContentProvenance.aiGenerated,
                          title: _prayerData!['title'] as String,
                          text: _prayerData!['text'] as String,
                          icon: VerbumIcons.heart,
                        ),
                        const SizedBox(height: VerbumSpace.md),
                        // Versículo motivador
                        if (_prayerData!['verse'] != null)
                          VSurfaceCard(
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
                                      size: 20,
                                      color: p.rubric,
                                    ),
                                    const SizedBox(width: VerbumSpace.xs),
                                    Text(
                                      'Versículo para ti',
                                      style: type.rubric,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: VerbumSpace.sm),
                                Text(
                                  _prayerData!['verse'] as String,
                                  style: type.scriptureLarge,
                                ),
                                if (_prayerData!['verseReference'] != null) ...[
                                  const SizedBox(height: VerbumSpace.xs),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _prayerData!['verseReference'] as String,
                                      style: type.citation,
                                    ),
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
                  padding: const EdgeInsets.fromLTRB(
                    VerbumSpace.gutter,
                    VerbumSpace.sm,
                    VerbumSpace.gutter,
                    VerbumSpace.md,
                  ),
                  child: VButton(
                    label: 'Regresar',
                    icon: VerbumIcons.arrowLeft,
                    iconLeading: true,
                    variant: VButtonVariant.outlined,
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
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
              ],
            ),
    );
  }
}
