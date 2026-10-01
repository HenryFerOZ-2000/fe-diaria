import 'package:flutter/material.dart';
import '../features/sharing/domain/share_content.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/traditional_prayers_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../faith/tradition_guard.dart';
import 'package:verbum/design_system/design_system.dart';

/// Pantalla principal de la Novena - Selección de día
class NovenaScreen extends StatefulWidget {
  const NovenaScreen({super.key});

  @override
  State<NovenaScreen> createState() => _NovenaScreenState();
}

class _NovenaScreenState extends State<NovenaScreen> {
  final TraditionalPrayersService _service = TraditionalPrayersService();
  bool _isLoading = true;
  bool _blockedByTradition = false;

  @override
  void initState() {
    super.initState();
    if (_blockIfEvangelical()) return;
    _loadData();
    _loadSavedProgress();
  }

  bool _blockIfEvangelical() {
    final blocked = TraditionGuard.blockCatholicOnlyModuleIfNeeded(
      context: context,
      moduleName: 'La novena',
      isMounted: () => mounted,
    );
    _blockedByTradition = blocked;
    return blocked;
  }

  void _loadSavedProgress() {
    final lastDay = StorageService().getNovenaLastDay();
    if (lastDay != null && lastDay >= 1 && lastDay <= 9) {
      // Mostrar indicador de continuación si hay progreso guardado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Puedes continuar desde el Día $lastDay'),
              action: SnackBarAction(
                label: 'Continuar',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NovenaDayScreen(day: lastDay),
                    ),
                  );
                },
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _loadData() async {
    try {
      await _service.loadPrayers();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading novena: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockedByTradition) {
      return const SizedBox.shrink();
    }
    final lastDay = StorageService().getNovenaLastDay();
    return Scaffold(
      appBar: AppBar(
        title: Text('Novena de Navidad', style: context.type.heading),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: VEmptyState(loading: true, title: 'Cargando…'),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  4,
                  VerbumSpace.gutter,
                  28,
                ),
                children: [
                  const VFeatureCard(
                    eyebrow: 'Nueve días',
                    title: 'Preparar el corazón para la Navidad',
                    body:
                        'Una tradición de nueve días de oración para celebrar el nacimiento de Jesús.',
                    watermark: VerbumIcons.starFour,
                  ),
                  const VSectionHeader(
                    'Selecciona un día',
                    padding: EdgeInsets.fromLTRB(2, 24, 2, 12),
                  ),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      for (var day = 1; day <= 9; day++)
                        VNumberTile(
                          number: day,
                          caption: 'Día',
                          state: lastDay != null && day < lastDay
                              ? VStepState.done
                              : lastDay == day
                              ? VStepState.current
                              : VStepState.upcoming,
                          semanticLabel: 'Día $day',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NovenaDayScreen(day: day),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Pantalla de un día específico de la Novena con navegación por pasos
class NovenaDayScreen extends StatefulWidget {
  final int day;

  const NovenaDayScreen({super.key, required this.day});

  @override
  State<NovenaDayScreen> createState() => _NovenaDayScreenState();
}

class _NovenaDayScreenState extends State<NovenaDayScreen> {
  final TraditionalPrayersService _service = TraditionalPrayersService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  int _currentStep = 1;
  int _totalSteps = 0;
  bool _isLoading = true;
  bool _blockedByTradition = false;

  @override
  void initState() {
    super.initState();
    if (_blockIfEvangelical()) return;
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
    _loadStepData();
    _loadSavedStep();
  }

  bool _blockIfEvangelical() {
    final blocked = TraditionGuard.blockCatholicOnlyModuleIfNeeded(
      context: context,
      moduleName: 'La novena',
      isMounted: () => mounted,
    );
    _blockedByTradition = blocked;
    return blocked;
  }

  void _loadSavedStep() {
    final lastDay = StorageService().getNovenaLastDay();
    final lastStep = StorageService().getNovenaLastStep();
    if (lastDay == widget.day && lastStep != null && lastStep > 1) {
      setState(() {
        _currentStep = lastStep;
      });
    }
  }

  Future<void> _loadStepData() async {
    try {
      await _service.loadPrayers();
      setState(() {
        _totalSteps = _service.getNovenaDayStepCount(widget.day);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading novena step: $e');
      setState(() {
        _isLoading = false;
      });
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

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      // Guardar progreso
      StorageService().saveNovenaProgress(widget.day, _currentStep);
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blockedByTradition) {
      return const SizedBox.shrink();
    }
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

    final p = context.palette;
    final type = context.type;
    final stepData = _service.getNovenaStep(widget.day, _currentStep);
    final title = stepData?['titulo'] as String? ?? '';
    final text = stepData?['texto'] as String? ?? '';
    final isCarol = title.toLowerCase().contains('villancico');
    final isLast = _currentStep >= _totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: Text('Día ${widget.day}', style: type.heading),
        centerTitle: true,
        actions: [
          if (stepData != null && !isCarol)
            VIconButton(
              icon: VerbumIcons.shareNetwork,
              semanticLabel: 'Compartir',
              variant: VIconButtonVariant.ghost,
              onPressed: () => ShareService.openComposer(
                context,
                ShareContent(
                  title: 'Novena de Navidad - Día ${widget.day}',
                  body: text,
                  reference: title,
                  kind: ShareContentKind.prayer,
                  tradition: ShareTradition.catholic,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: VEmptyState(loading: true, title: 'Cargando…'),
                    )
                  : stepData == null
                  ? const Center(
                      child: VEmptyState(
                        icon: VerbumIcons.warningCircle,
                        title: 'No se pudo cargar el paso',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: VProgressBar(
                                value: _currentStep / _totalSteps,
                                semanticLabel: 'Avance del día',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_currentStep/$_totalSteps',
                              style: type.caption.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        VIcon(
                          isCarol
                              ? VerbumIcons.musicNote
                              : VerbumIcons.bookOpenText,
                          weight: VIconWeight.duotone,
                          size: 32,
                          color: p.gold,
                        ),
                        const SizedBox(height: 12),
                        VRubricLabel('Paso $_currentStep de $_totalSteps'),
                        const SizedBox(height: 6),
                        Text(title, style: type.display.copyWith(fontSize: 30)),
                        const SizedBox(height: 20),
                        if (text.length >= 120)
                          VDropCapText(text, style: type.scripture)
                        else
                          Text(text, style: type.scripture),
                        const SizedBox(height: 24),
                        Center(
                          child: VButton(
                            label: 'Regresar al inicio',
                            icon: VerbumIcons.house,
                            iconLeading: true,
                            variant: VButtonVariant.text,
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/home'),
                          ),
                        ),
                      ],
                    ),
            ),
            if (stepData != null)
              VBottomBar(
                child: Row(
                  children: [
                    if (_currentStep > 1) ...[
                      VIconButton(
                        icon: VerbumIcons.arrowLeft,
                        semanticLabel: 'Paso anterior',
                        size: 50,
                        onPressed: _previousStep,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: VButton(
                        label: isLast ? 'Día completado' : 'Siguiente',
                        icon: isLast
                            ? VerbumIcons.check
                            : VerbumIcons.arrowRight,
                        expanded: true,
                        onPressed: isLast ? null : _nextStep,
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
