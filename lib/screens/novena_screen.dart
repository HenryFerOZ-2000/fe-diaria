import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/traditional_prayers_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';

/// Pantalla principal de la Novena - Selección de día
class NovenaScreen extends StatefulWidget {
  const NovenaScreen({super.key});

  @override
  State<NovenaScreen> createState() => _NovenaScreenState();
}

class _NovenaScreenState extends State<NovenaScreen> {
  final TraditionalPrayersService _service = TraditionalPrayersService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSavedProgress();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Novena de Navidad',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona un día',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La Novena de Navidad es una tradición de nueve días de preparación espiritual para celebrar el nacimiento de Jesús.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final day = index + 1;
                          final lastDay = StorageService().getNovenaLastDay();
                          final isCompleted = lastDay != null && day < lastDay;
                          final isInProgress = lastDay != null && day == lastDay;
                          
                          return _buildDayButton(
                            context: context,
                            colorScheme: colorScheme,
                            day: day,
                            isCompleted: isCompleted,
                            isInProgress: isInProgress,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => NovenaDayScreen(day: day),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDayButton({
    required BuildContext context,
    required ColorScheme colorScheme,
    required int day,
    required VoidCallback onTap,
    bool isCompleted = false,
    bool isInProgress = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.secondary,
                    size: 20,
                  )
                else if (isInProgress)
                  Icon(
                    Icons.play_circle_outline,
                    color: colorScheme.primary,
                    size: 20,
                  )
                else
                  Text(
                    'Día',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '$day',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isCompleted 
                        ? colorScheme.secondary 
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
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

  @override
  void initState() {
    super.initState();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
    _loadStepData();
    _loadSavedStep();
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

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stepData = _service.getNovenaStep(widget.day, _currentStep);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Día ${widget.day} - Paso $_currentStep',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : stepData == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se pudo cargar el paso',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Indicador de progreso
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: _currentStep / _totalSteps,
                                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.primary,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$_currentStep/$_totalSteps',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Contenido del paso
                                _buildStepCard(
                                  context: context,
                                  title: stepData['titulo'] as String? ?? '',
                                  text: stepData['texto'] as String? ?? '',
                                  colorScheme: colorScheme,
                                  isVillancico: (stepData['titulo'] as String? ?? '')
                                      .toLowerCase()
                                      .contains('villancico'),
                                ),
                                const SizedBox(height: 24),
                                // Botones de navegación
                                Row(
                                  children: [
                                    if (_currentStep > 1)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _previousStep,
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('Anterior'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.surface,
                                            foregroundColor: colorScheme.onSurface,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                    if (_currentStep > 1) const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _currentStep < _totalSteps
                                            ? _nextStep
                                            : null,
                                        icon: const Icon(Icons.arrow_forward),
                                        label: Text(_currentStep < _totalSteps ? 'Siguiente' : 'Finalizado'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Botón de regreso al inicio
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/home');
                                    },
                                    icon: const Icon(Icons.home, size: 24),
                                    label: Text(
                                      'Regresar al inicio',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
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
                        : Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required String title,
    required String text,
    required ColorScheme colorScheme,
    required bool isVillancico,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isVillancico
                      ? colorScheme.secondary.withOpacity(0.15)
                      : colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isVillancico ? Icons.music_note : Icons.book,
                  color: isVillancico ? colorScheme.secondary : colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 18,
              height: 1.8,
              color: colorScheme.onSurface,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 24),
          if (isVillancico)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continuar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ShareService.shareAsText(
                    text: text,
                    reference: title,
                    title: 'Novena de Navidad - Día ${widget.day}',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

