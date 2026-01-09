import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../widgets/streak_card.dart';
import '../controllers/missions_controller.dart';
import '../controllers/streak_controller.dart';
import 'daily_missions_flow_screen.dart';
import '../widgets/racha_celebration_dialog.dart';
import '../services/ads_service.dart';
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
      // NO marcar día como activo al iniciar la app
      // La racha solo se actualiza cuando se completan todas las misiones diarias
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
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openMissionRead(BuildContext context, Mission mission, AppProvider provider) {
    // Verificar si la oración de la noche está bloqueada
    if (mission.id == 'night' && !_isNightPrayerAvailable() && !mission.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La oración de la noche estará disponible a las 7:00 PM',
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
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
              await Future.delayed(const Duration(milliseconds: 800));
              
              // Forzar recarga del StreakController para asegurar que se actualice
              if (mounted) {
                final stats = await _spiritualStatsService.getStats();
                debugPrint('[HomeScreen] 📊 Current stats after completeAllMissions: currentStreak=${stats.currentStreak}, bestStreak=${stats.bestStreak}');
                
                // Forzar actualización del StreakController con forceUpdate=true
                // para permitir que se muestre el popup
                _streakController.reloadFromFirestore(forceUpdate: true);
                
                // Dar tiempo adicional para que el stream se actualice
                await Future.delayed(const Duration(milliseconds: 300));
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

  /// Verifica si la oración de la noche está disponible (después de las 7 PM)
  bool _isNightPrayerAvailable() {
    final now = DateTime.now();
    return now.hour >= 19; // 7 PM = 19:00
  }

  Widget _buildMissionCard(BuildContext context, Mission mission, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = mission.completed;
    final isNightMission = mission.id == 'night';
    final isBlocked = isNightMission && !_isNightPrayerAvailable() && !completed;
    
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
      onTap: isBlocked ? null : () => _openMissionRead(context, mission, provider),
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
        child: Opacity(
          opacity: isBlocked ? 0.6 : 1.0,
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
                  if (isBlocked)
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Disponible a las 7:00 PM',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  else
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
}
