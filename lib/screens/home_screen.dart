import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'dart:async';
import '../providers/app_provider.dart';
import '../design_system/design_system.dart';
import '../features/today/application/today_schedule.dart';
import '../features/today/presentation/cover_photos.dart';
import '../features/today/presentation/today_cover.dart';
import '../features/today/presentation/today_journey.dart';
import '../features/prayers/presentation/pray_now_carousel.dart';
import '../bible/ui/bible_continue_card.dart';
import '../services/share_service.dart';
import '../features/sharing/domain/share_content.dart';
import '../providers/auth_provider.dart';
import '../controllers/missions_controller.dart';
import '../controllers/streak_controller.dart';
import 'daily_missions_flow_screen.dart';
import '../widgets/racha_celebration_dialog.dart';
import '../services/spiritual_stats_service.dart';
import '../services/daily_progress_service.dart';
import '../widgets/spiritual_path_today_card.dart';
import '../features/liturgy/presentation/today_liturgy_section.dart';
import '../features/today/domain/daily_practice_catalog.dart';

/// Pantalla principal con diseño religioso elegante
/// Incluye tabs para Versículo del Día y Oración del Día
class HomeScreen extends StatefulWidget {
  final int? initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _prayerTransitionController;
  late Animation<double> _fadeAnimation;
  AudioPlayer? _audioPlayer;
  Timer? _prayerTimeCheckTimer;
  Timer? _dailyRefreshTimer;
  bool _isMorningPrayer = true;
  bool _streakDialogShowing = false;

  /// Pasada la portada, la barra de estado pasa a fondo lavanda y texto
  /// oscuro para que la hora siga legible.
  bool _pastCover = false;
  late final StreakController _streakController;
  final SpiritualStatsService _spiritualStatsService = SpiritualStatsService();
  final DailyProgressService _dailyProgressService = DailyProgressService();
  late final MissionsController _missionsController;

  @override
  void initState() {
    super.initState();
    _missionsController = MissionsController(
      missions: [
        Mission(
          id: 'verse',
          title: 'Recibe la Palabra',
          description:
              'Lee despacio el versículo bíblico de hoy en la edición RV1909.',
          icon: VerbumIcons.bookOpenText,
          durationMinutes: 1,
        ),
        Mission(
          id: 'morning',
          title: 'Hazla oración',
          description: 'Lleva el mensaje a una conversación personal con Dios.',
          icon: VerbumIcons.sun,
          durationMinutes: 2,
        ),
        dailyPracticeFor(DateTime.now()),
        Mission(
          id: 'night',
          title: 'Cierra tu día con Dios',
          description: 'Reconoce dónde estuvo Dios y descansa en su paz.',
          icon: VerbumIcons.moon,
          durationMinutes: 2,
          isOptional: true,
        ),
      ],
    );
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
      // NO marcar día como activo al iniciar la app
      // La racha solo se actualiza al completar los tres momentos esenciales.
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

  /// Carga el progreso diario desde Firestore y actualiza el estado de las misiones
  Future<void> _loadDailyProgress() async {
    try {
      final progress = await _dailyProgressService.getTodayProgress();
      if (!mounted) return;

      // Actualizar estado de misiones basado en Firestore
      for (final mission in _missionsController.missions) {
        final internalId = DailyProgressService.mapMissionIdToInternal(
          mission.id,
        );
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
    _audioPlayer?.dispose();
    _prayerTimeCheckTimer?.cancel();
    _dailyRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();
    // Sobre la foto, hora y batería en claro.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (_pastCover ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final verse = provider.todayVerse;
            final verseMission = _missionsController.missions
                .where((m) => m.id == 'verse')
                .firstOrNull;
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      final past = n.metrics.pixels > 380;
                      if (past != _pastCover) setState(() => _pastCover = past);
                      return false;
                    },
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ChangeNotifierProvider<StreakController>.value(
                          value: _streakController,
                          child: Consumer<StreakController>(
                            builder: (context, streak, _) {
                              _maybeShowStreakCelebration(streak);
                              return TodayCover(
                                now: now,
                                night: isCoverNight(now),
                                userName: auth.firebaseUser?.displayName,
                                streakDays: streak.totalDays,
                                verseText: verse?.text,
                                verseReference: verse?.reference,
                                onRead: verseMission == null
                                    ? null
                                    : () => _openMissionRead(
                                        context,
                                        verseMission,
                                        provider,
                                      ),
                                onShare: verse == null
                                    ? null
                                    : () => ShareService.openComposer(
                                        context,
                                        ShareContent(
                                          title: 'Palabra de hoy',
                                          body: verse.text,
                                          reference:
                                              '${verse.reference} · RV1909',
                                          sourceLabel: 'RV1909',
                                          kind: ShareContentKind.verse,
                                        ),
                                      ),
                                onProfile: () =>
                                    Navigator.of(context).pushNamed('/profile'),
                                onStreak: () =>
                                    Navigator.of(context).pushNamed('/streak'),
                              );
                            },
                          ),
                        ),
                        // El siguiente paso se monta sobre el final de la portada.
                        Transform.translate(
                          offset: const Offset(0, -64),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VerbumSpace.gutter,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TodayJourney(
                                  missions: _missionsController.missions,
                                  nightAvailable: isNightPrayerAvailable(now),
                                  onOpen: (mission) => _openMissionRead(
                                    context,
                                    mission,
                                    provider,
                                  ),
                                ),
                                if (provider.isLoading) ...[
                                  const SizedBox(height: 12),
                                  const VProgressBar(value: 0.35, height: 3),
                                ],
                                const SizedBox(height: 26),
                                const SpiritualPathTodayCard(),
                                const BibleContinueCard(),
                                PrayNowCarousel(now: now),
                                const SizedBox(height: 10),
                                const TodayLiturgySection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _pastCover ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          height: MediaQuery.paddingOf(context).top,
                          color: p.background.withValues(alpha: .96),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Muestra la celebración de racha una sola vez, después del frame.
  void _maybeShowStreakCelebration(StreakController streak) {
    if (!streak.showPopup || _streakDialogShowing) return;
    _streakDialogShowing = true;
    // Consumir el flag antes de mostrar para evitar múltiples diálogos.
    _streakController.consumePopup();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latestStreak = _streakController.totalDays;
      debugPrint(
        '[HomeScreen] Showing celebration dialog with streak: $latestStreak',
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (_) => RachaCelebrationDialog(totalDays: latestStreak),
      ).then((_) {
        if (mounted) {
          setState(() => _streakDialogShowing = false);
        } else {
          _streakDialogShowing = false;
        }
      });
    });
  }

  void _openMissionRead(
    BuildContext context,
    Mission mission,
    AppProvider provider,
  ) {
    // Verificar si la oración de la noche está bloqueada
    if (mission.id == 'night' &&
        !isNightPrayerAvailable(DateTime.now()) &&
        !mission.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              VIcon(
                VerbumIcons.lockSimple,
                size: 18,
                color: context.palette.onInk,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'La oración de la noche estará disponible a las 7:00 PM',
                ),
              ),
            ],
          ),
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
            // Incrementar la racha al completar los tres momentos esenciales.
            final isGuest = FirebaseAuth.instance.currentUser == null;
            try {
              if (isGuest) {
                await provider.completeDailyStreak();
              } else {
                debugPrint('[HomeScreen] Calling completeAllMissions...');
                await _spiritualStatsService.completeAllMissions();
                debugPrint(
                  '[HomeScreen] completeAllMissions called successfully',
                );
              }

              // Firestore necesita un instante para propagar el nuevo valor.
              if (!isGuest) {
                await Future.delayed(const Duration(milliseconds: 800));
              }

              if (mounted) {
                _streakController.reloadFromFirestore(forceUpdate: true);
              }
            } catch (e, stackTrace) {
              debugPrint(
                '[HomeScreen] ❌ Error calling completeAllMissions: $e',
              );
              debugPrint('[HomeScreen] Stack trace: $stackTrace');
              // Solo los usuarios autenticados tienen fallback remoto.
              if (!isGuest) {
                try {
                  await _spiritualStatsService.markActiveTodayOncePerDay(
                    force: true,
                  );
                } catch (e2) {
                  debugPrint(
                    '[HomeScreen] Error calling markActiveToday fallback: $e2',
                  );
                }
              }
            }
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  /// Verifica si la oración de la noche está disponible (después de las 7 PM)
}
