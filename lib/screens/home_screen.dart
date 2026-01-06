import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../models/prayer.dart';
import '../providers/app_provider.dart';
import '../widgets/streak_card.dart';
import '../controllers/missions_controller.dart';
import '../controllers/streak_controller.dart';
import 'daily_missions_flow_screen.dart';
import '../widgets/racha_celebration_dialog.dart';
import '../services/ads_service.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';
import '../services/ads_manager.dart';
import '../services/spiritual_stats_service.dart';
import '../services/daily_progress_service.dart';
import '../l10n/app_localizations.dart';

/// Pantalla principal con diseño religioso elegante
/// Incluye tabs para Versículo del Día y Oración del Día
class HomeScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const HomeScreen({super.key, this.initialTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _prayerTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _prayerFadeAnimation;
  AudioPlayer? _audioPlayer;
  Timer? _prayerTimeCheckTimer;
  Timer? _dailyRefreshTimer;
  bool _isMorningPrayer = true;
  bool _adsRemoved = false;
  bool _streakDialogShowing = false;
  late final StreakController _streakController;
  final SpiritualStatsService _spiritualStatsService = SpiritualStatsService();
  final DailyProgressService _dailyProgressService = DailyProgressService();
  // Se inicializa aquí para evitar LateInitializationError en hot reload.
  late final MissionsController _missionsController = MissionsController(
    missions: [
      Mission(id: 'verse', title: 'Leer el versículo del día', icon: Icons.menu_book),
      Mission(id: 'morning', title: 'Leer la oración del día', icon: Icons.wb_sunny),
      Mission(id: 'night', title: 'Leer la oración de la noche', icon: Icons.nightlight_round),
      Mission(id: 'family', title: 'Orar por un familiar', icon: Icons.family_restroom),
    ],
  );

  @override
  void initState() {
    super.initState();
    // Inicializar StreakController
    _streakController = StreakController();
    
    // Inicializar TabController (usa un AnimationController internamente)
    final initialIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: initialIndex.clamp(0, 1),
    );
    // Inicializar AnimationController para animaciones de contenido
    _setupAnimations();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
    _checkPrayerTime();
    _setupDailyRefresh();
    // Verificar cada minuto si cambió la hora de oración
    _prayerTimeCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkPrayerTime();
    });
    
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadTodayVerse();
      provider.loadTodayPrayers();
      // Intentar mostrar interstitial suave (máx 2 por día), no en lectura
      if (_tabController.index == 0) {
        AdsManager().maybeShowDailyInterstitial(
          context: context,
          isSensitiveContext: false,
        );
      }
      // Marcar día como activo si el usuario está autenticado (una vez al día)
      // Esto se llama al abrir la app para asegurar que el día esté marcado
      _spiritualStatsService.markActiveTodayOncePerDay().catchError((e) {
        debugPrint('[HomeScreen] Error marking active today on init: $e');
      });
      // Cargar progreso diario y actualizar estado de misiones
      _loadDailyProgress();
    });
  }
  
  void _setupDailyRefresh() {
    // Programar refresco automático a las 9:00 AM
    final now = DateTime.now();
    var nextRefresh = DateTime(now.year, now.month, now.day, 9, 0);
    
    // Si ya pasaron las 9 AM hoy, programar para mañana
    if (nextRefresh.isBefore(now)) {
      nextRefresh = nextRefresh.add(const Duration(days: 1));
    }
    
    final durationUntilRefresh = nextRefresh.difference(now);
    
    _dailyRefreshTimer = Timer(durationUntilRefresh, () {
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.refreshTodayVerse();
        provider.loadTodayPrayers();
        provider.loadTodayFamilyPrayer();
        
        // Programar el siguiente refresco para mañana a las 9 AM
        _setupDailyRefresh();
      }
    });
  }

  void _setupAnimations() {
    // Crear AnimationController para animaciones de fade del versículo
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Crear AnimationController para transiciones de oración (mañana/noche)
    _prayerTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _prayerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _prayerTransitionController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Iniciar animaciones
    _animationController.forward();
    _prayerTransitionController.forward();
  }

  void _checkPrayerTime() {
    final now = DateTime.now();
    final hour = now.hour;
    // Oración de la mañana: 5:00 AM a 5:59 PM
    // Oración de la noche: 6:00 PM a 4:59 AM
    final newIsMorning = hour >= 5 && hour < 18;
    
    if (newIsMorning != _isMorningPrayer) {
      setState(() {
        _isMorningPrayer = newIsMorning;
        // Animar transición suave
        _prayerTransitionController.reset();
        _prayerTransitionController.forward();
      });
      
      // Recargar oraciones cuando cambia el tiempo
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.loadTodayPrayers();
      }
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
          debugPrint('Banner ad loaded successfully');
        } else {
          ad.dispose();
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Failed to load banner ad: $error');
        // Reintentar después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_adsRemoved && _bannerAd == null) {
            _loadBannerAd();
          }
        });
      },
    );
  }

  /// Carga el progreso diario desde Firestore y actualiza el estado de las misiones
  Future<void> _loadDailyProgress() async {
    try {
      final progress = await _dailyProgressService.getTodayProgress();
      if (!mounted) return;

      // Actualizar estado de misiones basado en Firestore
      for (final mission in _missionsController.missions) {
        final internalId = DailyProgressService.mapMissionIdToInternal(mission.id);
        final isDone = progress.isMissionDone(internalId);
        if (isDone && !mission.completed) {
          _missionsController.completeMission(mission.id);
        } else if (!isDone && mission.completed) {
          // Si en Firestore no está hecho pero localmente sí, sincronizar
          mission.completed = false;
        }
      }
      
      if (mounted) {
        setState(() {}); // Actualizar UI
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error loading daily progress: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _prayerTransitionController.dispose();
    _streakController.dispose();
    _bannerAd?.dispose();
    _audioPlayer?.dispose();
    _prayerTimeCheckTimer?.cancel();
    _dailyRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Actualizar estado de anuncios removidos en cada build
    final storage = StorageService();
    final adsRemovedNow = storage.getAdsRemoved();
    if (adsRemovedNow && !_adsRemoved) {
      // Si se compró mientras esta vista estaba activa, liberar banner
      _bannerAd?.dispose();
      _bannerAd = null;
      _adsRemoved = true;
    } else if (!adsRemovedNow && _adsRemoved) {
      // Si se restauraron los anuncios, recargar banner
      _adsRemoved = false;
      _loadBannerAd();
    } else if (!adsRemovedNow && _bannerAd == null) {
      // Si no hay banner cargado y los anuncios no están removidos, cargar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_adsRemoved && _bannerAd == null) {
          _loadBannerAd();
        }
      });
    }
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF161522),
                    const Color(0xFF1E1B2E),
                    const Color(0xFF161522),
                  ]
                : [
                    const Color(0xFFF8FAFF),
                    const Color(0xFFE8F0FF),
                    const Color(0xFFF0F5FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno y elegante
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.2),
                            colorScheme.tertiary.withOpacity(0.15),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        localizations.appTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pushNamed('/profile'),
                      icon: const Icon(Icons.person_outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Contenido principal (sin tabs)
              Expanded(
                child: _buildVerseTab(context, isDark, localizations),
              ),
              // Banner Ad flotante - siempre visible en la parte inferior
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

  Widget _buildVerseTab(
      BuildContext context, bool isDark, AppLocalizations localizations) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChangeNotifierProvider<StreakController>.value(
                    value: _streakController,
                    child: Consumer<StreakController>(
                      builder: (context, streak, _) {
                        // Usar el valor actualizado del streak para el diálogo
                        final currentStreak = streak.totalDays;
                        
                        // Manejar el popup después del build para evitar setState durante build
                        if (streak.showPopup && !_streakDialogShowing) {
                          _streakDialogShowing = true;
                          // Consumir el flag antes de mostrar para evitar múltiples diálogos.
                          _streakController.consumePopup();
                          // Esperar después del build para mostrar el diálogo
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            // Obtener el valor más reciente del streak
                            final latestStreak = _streakController.totalDays;
                            debugPrint('[HomeScreen] Showing celebration dialog with streak: $latestStreak');
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black54,
                              builder: (_) => RachaCelebrationDialog(totalDays: latestStreak),
                            ).then((_) {
                              if (mounted) {
                                setState(() {
                                  _streakDialogShowing = false;
                                });
                              } else {
                                _streakDialogShowing = false;
                              }
                            });
                          });
                        }
                        return StreakCardDuolingoStyle(
                          totalDays: currentStreak,
                          playAnimation: streak.playAnimation,
                          weekDays: streak.days,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMissionsSection(context, provider),
                  const SizedBox(height: 16),
                  _buildSavedPrayersSection(
                    context: context,
                    prayers: provider.savedPrayers,
                      isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTab(
      BuildContext context, bool isDark, AppLocalizations localizations) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        final prayer = provider.currentPrayer;
        if (prayer == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDark
                      ? const Color(0xFFF5E6D3).withOpacity(0.5)
                      : const Color(0xFF2C1810).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.loadingError,
                  style: GoogleFonts.merriweather(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.loadTodayPrayers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(localizations.retry),
                ),
              ],
            ),
          );
        }

        return FadeTransition(
          opacity: _prayerFadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildPrayerCard(
                      context: context,
                      prayer: prayer,
                      isMorning: _isMorningPrayer,
                      onShare: () => ShareService.shareAsText(
                        text: prayer.text,
                        reference: prayer.title,
                        title: prayer.title,
                      ),
                      fontSize: provider.fontSize,
                      isDark: isDark,
                      localizations: localizations,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedPrayersSection({
    required BuildContext context,
    required List<Prayer> prayers,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withOpacity(0.75)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
                    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
          Row(
                            children: [
              Icon(
                Icons.favorite_border,
                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
              Text(
                'Tus oraciones',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.expand_more,
                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ],
                        ),
          const SizedBox(height: 12),
          if (prayers.isEmpty)
            Text(
              'Aún no guardas oraciones. Guarda tus favoritas para abrirlas aquí rápidamente.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: prayers
                  .map((prayer) => _buildSavedPrayerChip(
                        context: context,
                        prayer: prayer,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedPrayerChip({
    required BuildContext context,
    required Prayer prayer,
  }) {
    return InkWell(
      onTap: () => _showSavedPrayerDetail(context, prayer),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF9D7DFF),
              Color(0xFF7BD7FF),
                      ],
                    ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9D7DFF).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
                  ),
                ],
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                prayer.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedPrayerDetail(BuildContext context, Prayer prayer) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                prayer.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                prayer.text,
          style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.justify,
          ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ShareService.shareAsText(
                        text: prayer.text,
                        reference: prayer.title,
                        title: prayer.title,
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openMissionRead(BuildContext context, Mission mission, AppProvider provider) {
    final initialIndex = _missionsController.missions.indexOf(mission);
    if (initialIndex == -1) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyMissionsFlowScreen(
          missions: _missionsController.missions,
          initialMissionIndex: initialIndex,
          provider: provider,
          missionsController: _missionsController,
          dailyProgressService: _dailyProgressService,
          spiritualStatsService: _spiritualStatsService,
          onMissionComplete: (completedMission) {
            setState(() {
              // El estado se actualiza dentro de DailyMissionsFlowScreen
            });
          },
          onAllCompleted: () async {
            // Incrementar racha cuando se completan todas las misiones
            try {
              debugPrint('[HomeScreen] 🎯 Calling completeAllMissions...');
              await _spiritualStatsService.completeAllMissions();
              debugPrint('[HomeScreen] ✅ completeAllMissions called successfully');
              
              // Esperar a que Firestore se actualice
              await Future.delayed(const Duration(milliseconds: 500));
              
              // Forzar recarga del StreakController para asegurar que se actualice
              if (mounted) {
                final stats = await _spiritualStatsService.getStats();
                debugPrint('[HomeScreen] 📊 Current stats after completeAllMissions: currentStreak=${stats.currentStreak}, bestStreak=${stats.bestStreak}');
                
                // Forzar actualización del StreakController
                _streakController.reloadFromFirestore();
              }
            } catch (e, stackTrace) {
              debugPrint('[HomeScreen] ❌ Error calling completeAllMissions: $e');
              debugPrint('[HomeScreen] Stack trace: $stackTrace');
              // También intentar markActiveToday como fallback
              try {
                await _spiritualStatsService.markActiveTodayOncePerDay(force: true);
              } catch (e2) {
                debugPrint('[HomeScreen] ❌ Error calling markActiveToday fallback: $e2');
              }
            }
            if (mounted) {
              setState(() {
                provider.completeDailyStreak();
                // No llamar completeToday aquí - el stream actualizará automáticamente
                // _streakController.completeToday(DateTime.now().weekday - 1);
              });
            }
          },
        ),
      ),
    );
  }

  String _getMissionContent(String id, AppProvider provider) {
    switch (id) {
      case 'verse':
        return provider.todayVerse?.text ?? 'Versículo del día no disponible por el momento.';
      case 'morning':
        return provider.todayMorningPrayer?.text ?? 'Oración del día no disponible por el momento.';
      case 'night':
        return provider.todayEveningPrayer?.text ?? 'Oración de la noche no disponible por el momento.';
      case 'family':
        return provider.todayFamilyPrayer?.text ?? 'Señor, bendice a mi familia, cuida su salud y guíanos en amor. Amén.';
      default:
        return 'Contenido no disponible.';
    }
  }

  String? _getMissionReference(String id, AppProvider provider) {
    switch (id) {
      case 'verse':
        return provider.todayVerse?.reference;
      default:
        return null;
    }
  }

  double _missionsProgress() {
    final total = _missionsController.missions.length;
    final completed = _missionsController.missions.where((m) => m.completed).length;
    if (total == 0) return 0.0;
    return completed / total;
  }

  Widget _buildMissionCard(BuildContext context, Mission mission, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = mission.completed;
    final gradients = [
      [const Color(0xFF3C2A4D), const Color(0xFF6654A6)],
      [const Color(0xFF6A0F26), const Color(0xFFB83C3C)],
      [const Color(0xFF1F2A36), const Color(0xFF3B5C6B)],
      [const Color(0xFF1E3C2F), const Color(0xFF4E8B6F)],
    ];
    final idx = _missionsController.missions.indexOf(mission) % gradients.length;
    final gradient = gradients[idx];
    final durationText = _missionDurationLabel(mission.id);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openMissionRead(context, mission, provider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : mission.icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title.toUpperCase(),
          style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.white.withOpacity(completed ? 0.7 : 1),
                      decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    durationText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
            fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
          ),
                  ),
                ],
              ),
            ),
            Text(
              completed ? 'HECHO' : 'ABRIR',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 12,
              ),
          ),
          ],
        ),
      ),
    );
  }

  String _missionDurationLabel(String id) {
    switch (id) {
      case 'verse':
        return '1 MIN';
      case 'morning':
        return '2 MIN';
      case 'night':
        return '2 MIN';
      case 'family':
        return '2 MIN';
      default:
        return '';
    }
  }

  Widget _buildMissionsSection(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final allDone = _missionsController.isAllCompleted();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.push_pin_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Misiones de hoy',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ..._missionsController.missions.map((mission) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMissionCard(context, mission, provider),
            );
        }),
        if (allDone)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '¡Misiones completadas! Tu racha se actualizó.',
          style: GoogleFonts.inter(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerseCard({
    required BuildContext context,
    required dynamic verse,
    required bool isFavorite,
    required VoidCallback onFavoriteTap,
    required VoidCallback onShare,
    required double fontSize,
    required bool isDark,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Decoración de fondo sutil y moderna
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
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header moderno con icono y acciones - más compacto
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colorScheme.primary,
                        size: isCompact ? 20 : 24,
                      ),
                    ),
                    const Spacer(),
                    // Botón compartir con texto
                    _buildShareButton(
                      context: context,
                      onTap: onShare,
                      isDark: isDark,
                      isCompact: isCompact,
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    _buildActionButton(
                      context: context,
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      onTap: onFavoriteTap,
                      isDark: isDark,
                      isFavorite: isFavorite,
                      isCompact: isCompact,
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 12 : 24),
                // Texto del versículo con tipografía moderna - Flexible para scroll interno si es necesario
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      verse.text,
                      style: GoogleFonts.inter(
                        fontSize: (isCompact ? 17 : 18) * fontSize,
                        height: isCompact ? 1.6 : 1.7,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                      softWrap: true,
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 20),
                // Línea decorativa moderna
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.3),
                        colorScheme.tertiary.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 16),
                // Referencia con estilo elegante
                Row(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: colorScheme.secondary,
                      size: isCompact ? 18 : 20,
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Expanded(
                      child: Text(
                        verse.reference,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: (isCompact ? 16 : 18) * fontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard({
    required BuildContext context,
    required dynamic prayer,
    required bool isMorning,
    required VoidCallback onShare,
    required double fontSize,
    required bool isDark,
    required AppLocalizations localizations,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // Colores modernos según si es mañana o noche
    final accentColor = isMorning 
        ? const Color(0xFFFFB84D) // Dorado cálido para mañana
        : colorScheme.tertiary; // Azul cielo para noche

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración de fondo sutil y moderna
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.06,
              child: Icon(
                isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                size: 140,
                color: accentColor,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header moderno con icono y título
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                      ),
                      child: Icon(
                        isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                        color: accentColor,
                        size: isCompact ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isCompact ? 10 : 12),
                    Expanded(
                      child: Text(
                        isMorning
                            ? localizations.morningPrayer
                            : localizations.eveningPrayer,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: (isCompact ? 18 : 22) * fontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildShareButton(
                      context: context,
                      onTap: onShare,
                      isDark: isDark,
                      isCompact: isCompact,
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 12 : 24),
                // Texto de la oración con tipografía moderna - Flexible para scroll interno si es necesario
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      prayer.text,
                      style: GoogleFonts.inter(
                        fontSize: (isCompact ? 17 : 17) * fontSize,
                        height: isCompact ? 1.6 : 1.7,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withOpacity(0.9),
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                      softWrap: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required BuildContext context,
    required VoidCallback onTap,
    required bool isDark,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Compartir',
            style: GoogleFonts.inter(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isFavorite = false,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = isFavorite
        ? Colors.red
        : colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 7 : 10),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
            border: Border.all(
              color: buttonColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: buttonColor,
            size: isCompact ? 18 : 20,
          ),
        ),
      ),
    );
  }

  void _showShareDialog({
    required String text,
    required String reference,
    required BuildContext context,
    required AppLocalizations localizations,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.shareVerse,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.text_fields,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(localizations.shareAsText),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareAsText(
                  text: text,
                  reference: reference,
                  title: localizations.homeTitle,
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(localizations.shareAsImage),
              onTap: () {
                Navigator.pop(context);
                final provider = Provider.of<AppProvider>(context, listen: false);
                final colorScheme = Theme.of(context).colorScheme;
                ShareService.shareAsImage(
                  text: text,
                  reference: reference,
                  context: context,
                  title: localizations.homeTitle,
                  backgroundColor: provider.darkMode
                      ? colorScheme.surface
                      : colorScheme.surface,
                  textColor: provider.darkMode
                      ? colorScheme.onSurface
                      : colorScheme.onSurface,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
