import 'package:flutter/material.dart';
import '../features/sharing/domain/share_content.dart';
import '../faith/content_provenance.dart';
import '../services/category_prayers_service.dart';
import '../services/share_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/prayer_card.dart';
import 'package:verbum/design_system/design_system.dart';

class CategoryPrayersScreen extends StatefulWidget {
  const CategoryPrayersScreen({super.key});

  @override
  State<CategoryPrayersScreen> createState() => _CategoryPrayersScreenState();
}

class _CategoryPrayersScreenState extends State<CategoryPrayersScreen> {
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

    final service = CategoryPrayersService();
    final categories = service.categories;
    final p = context.palette;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: p.background,
      appBar: const VAppBar(title: Text('Oraciones para…')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  4,
                  VerbumSpace.gutter,
                  VerbumSpace.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VSectionHeader(
                      'Elige una categoría',
                      eyebrow: 'INTENCIONES',
                      padding: EdgeInsets.fromLTRB(2, 4, 2, 14),
                    ),
                    VTileGrid(
                      children: [
                        for (final entry in categories.entries)
                          VCategoryTile(
                            icon:
                                _getCategoryIcon(entry.value) ??
                                VerbumIcons.handsPraying,
                            title: entry.value,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CategoryPrayerDetailScreen(
                                        categoryKey: entry.key,
                                      ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!_adsRemoved) _BannerSlot(ad: _bannerAd),
            const _HomeButton(),
          ],
        ),
      ),
    );
  }

  VerbumIcons? _getCategoryIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('familia')) {
      return VerbumIcons.usersThree;
    }
    if (titleLower.contains('salud')) return VerbumIcons.heart;
    if (titleLower.contains('trabajo')) return VerbumIcons.briefcase;
    if (titleLower.contains('finanzas')) {
      return VerbumIcons.wallet;
    }
    if (titleLower.contains('hogar')) return VerbumIcons.house;
    if (titleLower.contains('protección') ||
        titleLower.contains('proteccion')) {
      return VerbumIcons.shield;
    }
    if (titleLower.contains('descanso')) return VerbumIcons.moonStars;
    if (titleLower.contains('mente') || titleLower.contains('paz')) {
      return VerbumIcons.personSimpleTaiChi;
    }
    if (titleLower.contains('ánimo') || titleLower.contains('animo')) {
      return VerbumIcons.smiley;
    }
    if (titleLower.contains('agradecimiento')) return VerbumIcons.confetti;
    return null;
  }
}

class CategoryPrayerDetailScreen extends StatefulWidget {
  final String categoryKey;
  const CategoryPrayerDetailScreen({super.key, required this.categoryKey});

  @override
  State<CategoryPrayerDetailScreen> createState() =>
      _CategoryPrayerDetailScreenState();
}

class _CategoryPrayerDetailScreenState
    extends State<CategoryPrayerDetailScreen> {
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
    final service = CategoryPrayersService();
    final title = service.categories[widget.categoryKey] ?? 'Categoría';
    final prayerText = service.getPrayerForCategory(widget.categoryKey);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.palette.background,
      appBar: VAppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  4,
                  VerbumSpace.gutter,
                  VerbumSpace.xl,
                ),
                child: _buildPrayerCard(
                  context: context,
                  title: title,
                  prayerText: prayerText,
                ),
              ),
            ),
            if (!_adsRemoved) _BannerSlot(ad: _bannerAd),
            const _HomeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard({
    required BuildContext context,
    required String title,
    required String prayerText,
  }) {
    return PrayerCard(
      provenance: ContentProvenance.aiGenerated,
      title: title,
      text: prayerText,
      icon: VerbumIcons.bookOpenText,
      onShare: () => ShareService.openComposer(
        context,
        ShareContent(
          title: title,
          body: prayerText,
          reference: title,
          kind: ShareContentKind.prayer,
        ),
      ),
    );
  }
}

/// Espacio fijo del banner publicitario (con indicador mientras carga).
class _BannerSlot extends StatelessWidget {
  const _BannerSlot({required this.ad});

  final BannerAd? ad;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: ad != null ? ad!.size.height.toDouble() : 50,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: ad != null
          ? AdWidget(ad: ad!)
          : SizedBox(
              height: 50,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: p.rubric,
                ),
              ),
            ),
    );
  }
}

/// Botón inferior para volver a la pantalla de inicio.
class _HomeButton extends StatelessWidget {
  const _HomeButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
        onPressed: () => Navigator.of(context).pushNamed('/home'),
      ),
    );
  }
}
