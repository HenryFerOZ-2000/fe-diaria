import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/rosary_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../faith/tradition_guard.dart';
import 'package:verbum/design_system/design_system.dart';

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
  bool _blockedByTradition = false;

  @override
  void initState() {
    super.initState();
    if (_blockIfEvangelical()) return;
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
    _loadData();
  }

  bool _blockIfEvangelical() {
    final blocked = TraditionGuard.blockCatholicOnlyModuleIfNeeded(
      context: context,
      moduleName: 'La guía del rosario',
      isMounted: () => mounted,
    );
    _blockedByTradition = blocked;
    return blocked;
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
    if (_blockedByTradition) {
      return const SizedBox.shrink();
    }
    final p = context.palette;
    final type = context.type;
    final guide = _service.getGuide();
    final todayMysteries = _service.getTodayMysteries();
    final steps = _service.getAllSteps();
    final step = steps.isNotEmpty && _currentStep < steps.length
        ? steps[_currentStep]
        : null;
    final isLast = _currentStep >= steps.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('Santo Rosario', style: type.heading)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: VEmptyState(loading: true, title: 'Cargando…'),
                    )
                  : guide == null
                  ? const Center(
                      child: VEmptyState(
                        icon: VerbumIcons.warningCircle,
                        title: 'No se pudo cargar la guía',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        VerbumSpace.gutter,
                        4,
                        VerbumSpace.gutter,
                        24,
                      ),
                      children: [
                        VFeatureCard(
                          eyebrow: 'Con María',
                          title: guide.title,
                          body: guide.description,
                          photo: VerbumPhotos.rosary,
                        ),
                        if (todayMysteries != null) ...[
                          VSectionHeader(
                            todayMysteries.name,
                            eyebrow: 'Misterios de hoy · ${todayMysteries.day}',
                            padding: const EdgeInsets.fromLTRB(2, 24, 2, 10),
                          ),
                          VSurfaceCard(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Column(
                              children: [
                                for (final (i, mystery)
                                    in todayMysteries.mysteries.indexed)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          child: Text(
                                            '${i + 1}',
                                            style: type.heading.copyWith(
                                              color: p.rubric,
                                              fontSize: 19,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            mystery,
                                            style: type.body.copyWith(
                                              color: p.ink,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (step != null) ...[
                          const VSectionHeader(
                            'Paso a paso',
                            eyebrow: 'Reza el Rosario',
                            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
                          ),
                          VSurfaceCard(
                            framed: true,
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: VRubricLabel(
                                        'Paso ${_currentStep + 1} de ${steps.length}',
                                      ),
                                    ),
                                    if (step.repetitions != null)
                                      VMetaChip(
                                        icon: VerbumIcons.arrowsClockwise,
                                        label: '${step.repetitions} veces',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                VProgressBar(
                                  value: (_currentStep + 1) / steps.length,
                                  height: 3,
                                ),
                                const SizedBox(height: 16),
                                Text(step.title, style: type.title),
                                const SizedBox(height: 12),
                                Text(
                                  step.prayer,
                                  style: type.scripture.copyWith(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            if (step != null)
              VBottomBar(
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      VIconButton(
                        icon: VerbumIcons.arrowLeft,
                        semanticLabel: 'Paso anterior',
                        size: 50,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: VButton(
                        label: isLast ? 'Rosario completado' : 'Siguiente',
                        icon: isLast
                            ? VerbumIcons.check
                            : VerbumIcons.arrowRight,
                        expanded: true,
                        onPressed: isLast
                            ? null
                            : () => setState(() => _currentStep++),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_adsRemoved)
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: _bannerAd != null
                    ? _bannerAd!.size.height.toDouble()
                    : 50,
                color: p.surface,
                child: _bannerAd != null
                    ? AdWidget(ad: _bannerAd!)
                    : const SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
