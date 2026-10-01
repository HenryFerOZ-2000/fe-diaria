import 'package:flutter/material.dart';
import '../features/sharing/domain/share_content.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/traditional_prayers_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../faith/tradition_guard.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/novena/presentation/novena_themes.dart';

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

  /// Abre un día y, al volver, refresca el avance (último día).
  Future<void> _openDay(int day) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NovenaDayScreen(day: day)));
    if (mounted) setState(() {});
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
    final saved = StorageService().getNovenaLastDay();
    final lastDay = saved != null && saved >= 1 && saved <= 9 ? saved : null;
    return Scaffold(
      appBar: VAppBar(
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
                  // El avance se ofrece aquí, en la propia tarjeta: un aviso
                  // flotante seguía visible al entrar a los días.
                  VFeatureCard(
                    eyebrow: 'Nueve días',
                    title: 'Preparar el corazón para la Navidad',
                    body:
                        'Una tradición de nueve días de oración para celebrar el nacimiento de Jesús.',
                    // La foto acompaña la virtud del día que toca.
                    photo: novenaThemeFor(lastDay ?? 1).photo,
                    footer: VButton(
                      label: lastDay == null
                          ? 'Comenzar el día 1'
                          : 'Continuar en el día $lastDay',
                      icon: lastDay == null
                          ? VerbumIcons.arrowRight
                          : VerbumIcons.bookmarkSimple,
                      iconLeading: lastDay != null,
                      variant: VButtonVariant.inverse,
                      compact: true,
                      onPressed: () => _openDay(lastDay ?? 1),
                    ),
                  ),
                  const VSectionHeader(
                    'Nueve días, nueve virtudes',
                    padding: EdgeInsets.fromLTRB(2, 24, 2, 12),
                  ),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .78,
                    children: [
                      for (var day = 1; day <= 9; day++)
                        _NovenaDayTile(
                          day: day,
                          done: lastDay != null && day < lastDay,
                          current: lastDay == day,
                          onTap: () => _openDay(day),
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

  /// Marca el día como hecho (el siguiente queda para continuar) y vuelve.
  void _completeDay() {
    StorageService().saveNovenaProgress(widget.day < 9 ? widget.day + 1 : 9, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.day < 9
              ? 'Día ${widget.day} completado. Mañana: ${novenaThemeFor(widget.day + 1).name.toLowerCase()}.'
              : '¡Terminaste la Novena! Feliz Navidad.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.of(context).pop();
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
      appBar: VAppBar(
        title: Text(
          'Día ${widget.day} · ${novenaThemeFor(widget.day).name}',
          style: type.heading,
        ),
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
                        const SizedBox(height: 18),
                        _NovenaThemeBanner(day: widget.day),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            VIcon(
                              isCarol
                                  ? VerbumIcons.musicNote
                                  : VerbumIcons.bookOpenText,
                              size: 18,
                              color: p.rubric,
                            ),
                            const SizedBox(width: 8),
                            VRubricLabel('Paso $_currentStep de $_totalSteps'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(title, style: type.display.copyWith(fontSize: 30)),
                        const SizedBox(height: 20),
                        if (text.length >= 120)
                          VDropCapText(text, style: type.scripture)
                        else
                          Text(text, style: type.scripture),
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
                        label: isLast ? 'Terminar el día' : 'Siguiente',
                        icon: isLast
                            ? VerbumIcons.check
                            : VerbumIcons.arrowRight,
                        expanded: true,
                        onPressed: isLast ? _completeDay : _nextStep,
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

/// Un día de la novena: su icono, el número y la virtud del día.
class _NovenaDayTile extends StatelessWidget {
  const _NovenaDayTile({
    required this.day,
    required this.done,
    required this.current,
    required this.onTap,
  });

  final int day;
  final bool done;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final theme = novenaThemeFor(day);
    final (Color box, Color fg) = done
        ? (p.sage, p.surface)
        : current
        ? (Colors.white.withValues(alpha: .6), p.onButter)
        : (p.surfaceMuted, p.rubric);
    final state = done
        ? ', hecho'
        : current
        ? ', para continuar'
        : '';
    return VSurfaceCard(
      tone: current ? VSurfaceTone.butter : VSurfaceTone.paper,
      radius: VerbumRadius.tile,
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
      onTap: onTap,
      semanticLabel: 'Día $day, ${theme.name}$state',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: box,
              borderRadius: BorderRadius.circular(13),
            ),
            child: VIcon(
              done ? VerbumIcons.check : theme.icon,
              size: 20,
              weight: done ? VIconWeight.regular : VIconWeight.duotone,
              color: fg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Día $day',
            style: type.bodyStrong.copyWith(
              color: current ? p.onButter : p.ink,
            ),
          ),
          Text(
            theme.name.replaceFirst(RegExp(r'^(La|El) '), ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: type.caption.copyWith(
              color: current ? p.onButter : p.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera de un día: foto de la temática, la virtud y una línea.
class _NovenaThemeBanner extends StatelessWidget {
  const _NovenaThemeBanner({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final theme = novenaThemeFor(day);
    return VSurfaceCard(
      radius: VerbumRadius.card,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          VPhotoFrame(theme.photo, width: 72, aspectRatio: 1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VIcon(theme.icon, size: 15, color: p.rubric),
                    const SizedBox(width: 6),
                    Text(
                      'Día $day de 9',
                      style: type.caption.copyWith(
                        color: p.rubric,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(theme.name, style: type.heading.copyWith(fontSize: 18)),
                Text(theme.line, style: type.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
