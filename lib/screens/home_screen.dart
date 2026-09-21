import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../widgets/streak_card.dart';
import '../controllers/missions_controller.dart';
import '../controllers/streak_controller.dart';
import 'daily_missions_flow_screen.dart';
import '../widgets/racha_celebration_dialog.dart';
import '../services/spiritual_stats_service.dart';
import '../services/daily_progress_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/verbum_header_actions.dart';
import '../widgets/spiritual_path_today_card.dart';
import '../features/liturgy/presentation/today_liturgy_section.dart';

Mission _buildDailyPracticeMission(DateTime date) {
  final practices = <Mission>[
    Mission(
      id: 'practice',
      title: 'Tres motivos para agradecer',
      description: 'Reconoce la presencia de Dios en lo sencillo.',
      icon: Icons.auto_awesome_rounded,
      durationMinutes: 2,
      content:
          'Haz una pausa y piensa en tres regalos que hayas recibido hoy. Pueden ser pequeños: una conversación, una oportunidad, un momento de calma.\n\nNómbralos uno por uno y di: “Gracias, Dios, por este regalo”.',
    ),
    Mission(
      id: 'practice',
      title: 'Ora por alguien',
      description: 'Pon delante de Dios a una persona que lo necesite.',
      icon: Icons.favorite_outline_rounded,
      durationMinutes: 2,
      content:
          'Piensa en una persona que esté atravesando una dificultad. Pronuncia su nombre en silencio y confía su vida a Dios.\n\nPide por su paz, su fortaleza y por aquello que más necesite en este momento.',
    ),
    Mission(
      id: 'practice',
      title: 'Un minuto de silencio',
      description: 'Deja el ruido y permanece un momento con Dios.',
      icon: Icons.spa_outlined,
      durationMinutes: 1,
      content:
          'Busca una postura cómoda, respira lentamente y permanece un minuto en silencio.\n\nNo necesitas encontrar palabras. Cuando aparezca una distracción, vuelve con calma a esta frase: “Aquí estoy, Señor”.',
    ),
    Mission(
      id: 'practice',
      title: 'Escribe una intención',
      description: 'Dale un nombre a lo que hoy llevas en el corazón.',
      icon: Icons.edit_note_rounded,
      durationMinutes: 2,
      content:
          'Detente y reconoce qué ocupa hoy tu corazón. Escríbelo en una frase breve en tus notas personales o en un papel.\n\nDespués entrégaselo a Dios con confianza: “Señor, pongo esta intención en tus manos”.',
    ),
    Mission(
      id: 'practice',
      title: 'Comparte una palabra de ánimo',
      description: 'Convierte la fe de hoy en cercanía para alguien.',
      icon: Icons.mark_chat_read_outlined,
      durationMinutes: 3,
      content:
          'Piensa en alguien que necesite compañía o esperanza. Envíale un mensaje breve y sincero para recordarle que no está solo.\n\nNo hace falta dar consejos; basta con estar presente.',
    ),
    Mission(
      id: 'practice',
      title: 'Haz un gesto de bondad',
      description: 'Lleva la Palabra a una acción concreta.',
      icon: Icons.volunteer_activism_outlined,
      durationMinutes: 3,
      content:
          'Elige un gesto sencillo que puedas realizar hoy: ayudar sin que te lo pidan, escuchar con paciencia, ceder tu lugar o agradecer de corazón.\n\nHazlo discretamente y ofrece ese gesto a Dios.',
    ),
    Mission(
      id: 'practice',
      title: 'Guarda una frase contigo',
      description: 'Elige una palabra del versículo para volver a ella hoy.',
      icon: Icons.bookmark_border_rounded,
      durationMinutes: 2,
      content:
          'Regresa mentalmente al versículo de hoy y elige la frase que más te haya tocado.\n\nRepítela lentamente tres veces. Déjala acompañarte durante el resto del día.',
    ),
    Mission(
      id: 'practice',
      title: 'Da un paso hacia la paz',
      description: 'Abre un espacio interior para perdonar o pedir perdón.',
      icon: Icons.handshake_outlined,
      durationMinutes: 3,
      content:
          'Piensa con serenidad si hoy puedes dar un pequeño paso hacia la reconciliación. Tal vez sea escuchar, reconocer un error o dejar de alimentar un resentimiento.\n\nNo necesitas resolverlo todo ahora. Pide a Dios la humildad y la sabiduría para comenzar.',
    ),
    Mission(
      id: 'practice',
      title: 'Ora por tu comunidad',
      description: 'Amplía tu oración hacia las necesidades de los demás.',
      icon: Icons.groups_2_outlined,
      durationMinutes: 2,
      content:
          'Recuerda a las personas que forman parte de tu comunidad, tu barrio o tu iglesia.\n\nPide por quienes están solos, enfermos o preocupados, y también por quienes sirven silenciosamente a los demás.',
    ),
  ];
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return practices[dayOfYear % practices.length];
}

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
          icon: Icons.menu_book_rounded,
          durationMinutes: 1,
        ),
        Mission(
          id: 'morning',
          title: 'Hazla oración',
          description: 'Lleva el mensaje a una conversación personal con Dios.',
          icon: Icons.wb_sunny_outlined,
          durationMinutes: 2,
        ),
        _buildDailyPracticeMission(DateTime.now()),
        Mission(
          id: 'night',
          title: 'Cierra tu día con Dios',
          description: 'Reconoce dónde estuvo Dios y descansa en su paz.',
          icon: Icons.nightlight_round,
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
                    const Color(0xFF15121D),
                    const Color(0xFF241E31),
                    const Color(0xFF17141F),
                  ]
                : [
                    const Color(0xFFF8F4EC),
                    const Color(0xFFF0E8DA),
                    const Color(0xFFF8F5EF),
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
                            colorScheme.primary.withValues(alpha: 0.2),
                            colorScheme.tertiary.withValues(alpha: 0.15),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting().toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            localizations.appTitle,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerbumHeaderActions(padding: EdgeInsets.zero),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Contenido principal (sin tabs)
              Expanded(child: _buildVerseTab(context, isDark, localizations)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Comienza el día en su presencia';
    if (hour < 19) return 'Haz una pausa para el alma';
    return 'Termina el día en paz';
  }

  Widget _buildVerseTab(
    BuildContext context,
    bool isDark,
    AppLocalizations localizations,
  ) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.isLoading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .08),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                            debugPrint(
                              '[HomeScreen] Showing celebration dialog with streak: $latestStreak',
                            );
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black54,
                              builder: (_) => RachaCelebrationDialog(
                                totalDays: latestStreak,
                              ),
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
                          completedMoments:
                              _missionsController.completedEssentialCount,
                          totalMoments:
                              _missionsController.essentialMissions.length,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/streak'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TodayLiturgySection(),
                  const SpiritualPathTodayCard(),
                  const SizedBox(height: 22),
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

  void _openMissionRead(
    BuildContext context,
    Mission mission,
    AppProvider provider,
  ) {
    // Verificar si la oración de la noche está bloqueada
    if (mission.id == 'night' &&
        !_isNightPrayerAvailable() &&
        !mission.completed) {
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
  bool _isNightPrayerAvailable() {
    final now = DateTime.now();
    return now.hour >= 19; // 7 PM = 19:00
  }

  Widget _buildMissionCard(
    BuildContext context,
    Mission mission,
    AppProvider provider,
  ) {
    final completed = mission.completed;
    final accent = _missionColor(mission.id);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF30243F), accent, .42)!,
              const Color(0xFF17131F),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: .55)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .28),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _openMissionRead(context, mission, provider),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  top: -18,
                  child: Icon(
                    mission.icon,
                    color: Colors.white.withValues(alpha: .09),
                    size: 116,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .24),
                            ),
                          ),
                          child: Text(
                            completed ? 'COMPLETADO' : 'TU SIGUIENTE PASO',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFFFFFF),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .18),
                            ),
                          ),
                          child: Icon(
                            completed ? Icons.check_rounded : mission.icon,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      mission.title,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: .45),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        mission.description,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF7F2F9),
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Color(0xFFF7F2F9),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${mission.durationMinutes} min',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFFFFFF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFCF7),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .18),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                completed ? 'Volver a leer' : 'Comenzar',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF261E36),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF261E36),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _missionColor(String id) {
    switch (id) {
      case 'verse':
        return const Color(0xFF77649A);
      case 'morning':
        return const Color(0xFFB58A45);
      case 'practice':
        return const Color(0xFF5F8178);
      case 'night':
        return const Color(0xFF536C91);
      default:
        return const Color(0xFF77649A);
    }
  }

  Widget _buildJourneyStep(
    BuildContext context,
    Mission mission,
    AppProvider provider, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final completed = mission.completed;
    final accent = _missionColor(mission.id);
    final visibleAccent = isDark
        ? Color.lerp(accent, Colors.white, .34)!
        : Color.lerp(accent, Colors.black, .10)!;
    final cardSurface = isDark
        ? const Color(0xFF2B2633)
        : const Color(0xFFFFFCF6);
    final titleColor = isDark
        ? (completed ? const Color(0xFFD8D0DE) : const Color(0xFFFAF7FC))
        : (completed ? const Color(0xFF514A58) : const Color(0xFF251F2B));
    final supportingColor = isDark
        ? const Color(0xFFC7BECD)
        : const Color(0xFF625A68);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: completed ? visibleAccent : cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed
                        ? visibleAccent
                        : visibleAccent.withValues(alpha: .72),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  completed ? Icons.check_rounded : mission.icon,
                  size: 14,
                  color: completed ? const Color(0xFF18131D) : visibleAccent,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 42,
                  color: visibleAccent.withValues(alpha: .30),
                ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: cardSurface,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openMissionRead(context, mission, provider),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: titleColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              completed
                                  ? 'Momento completado'
                                  : '${mission.durationMinutes} min · Más adelante',
                              style: GoogleFonts.inter(
                                color: supportingColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: visibleAccent,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNightInvitation(
    BuildContext context,
    Mission mission,
    AppProvider provider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final available = _isNightPrayerAvailable() || mission.completed;
    final visibleAccent = isDark
        ? const Color(0xFFB8CBE7)
        : const Color(0xFF3F587D);
    final cardSurface = isDark
        ? const Color(0xFF272734)
        : const Color(0xFFF7F9FC);
    final titleColor = isDark
        ? const Color(0xFFF7F4FA)
        : const Color(0xFF25212A);
    final supportingColor = isDark
        ? const Color(0xFFC5C4D0)
        : const Color(0xFF5D5B65);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: visibleAccent.withValues(alpha: .34)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: available
              ? () => _openMissionRead(context, mission, provider)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: visibleAccent.withValues(alpha: isDark ? .20 : .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mission.completed
                        ? Icons.check_rounded
                        : Icons.nightlight_round,
                    color: visibleAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.completed
                            ? 'Cierre del día completado'
                            : 'Para esta noche · Opcional',
                        style: GoogleFonts.inter(
                          color: visibleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.title,
                        style: GoogleFonts.playfairDisplay(
                          color: titleColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        available
                            ? '${mission.durationMinutes} min · ${mission.description}'
                            : 'Disponible desde las 19:00',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: supportingColor,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  available
                      ? Icons.arrow_forward_rounded
                      : Icons.schedule_rounded,
                  color: visibleAccent,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionsSection(BuildContext context, AppProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allDone = _missionsController.isAllCompleted();
    final essentials = _missionsController.essentialMissions;
    final completed = _missionsController.completedEssentialCount;
    final nextMission = _missionsController.nextEssentialMission;
    final optionalMission = _missionsController.missions
        .where((mission) => mission.isOptional)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TU RITMO ESPIRITUAL',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tu camino de hoy',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$completed de ${essentials.length} momentos',
              style: GoogleFonts.inter(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: essentials.isEmpty ? 0 : completed / essentials.length,
            ),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: colorScheme.primary.withValues(alpha: .10),
              color: allDone ? const Color(0xFF5F8178) : colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 17),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          child: nextMission != null
              ? _buildMissionCard(context, nextMission, provider)
              : Container(
                  key: const ValueKey('journey_complete'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      const Color(0xFF5F8178).withValues(alpha: .12),
                      colorScheme.surface,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF5F8178).withValues(alpha: .25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF5F8178),
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu camino de hoy está completo',
                              style: GoogleFonts.playfairDisplay(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'La racha ya está a salvo. Regresa esta noche si deseas cerrar el día en oración.',
                              style: GoogleFonts.inter(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 17),
        ...essentials.asMap().entries.map((entry) {
          final mission = entry.value;
          if (mission == nextMission) return const SizedBox.shrink();
          return _buildJourneyStep(
            context,
            mission,
            provider,
            isLast: entry.key == essentials.length - 1,
          );
        }),
        if (optionalMission != null) ...[
          const SizedBox(height: 7),
          _buildNightInvitation(context, optionalMission, provider),
        ],
      ],
    );
  }
}
