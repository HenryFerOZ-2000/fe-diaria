import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/missions_controller.dart';
import '../providers/app_provider.dart';
import '../services/share_service.dart';
import '../services/daily_progress_service.dart';
import '../services/spiritual_stats_service.dart';
import '../widgets/prayer_reading_experience.dart';

/// Pantalla contenedora que maneja el flujo de misiones diarias
/// usando PageView para transiciones fluidas tipo wizard
class DailyMissionsFlowScreen extends StatefulWidget {
  final List<Mission> missions;
  final int initialMissionIndex;
  final AppProvider provider;
  final MissionsController missionsController;
  final DailyProgressService dailyProgressService;
  final SpiritualStatsService spiritualStatsService;
  final Function(Mission) onMissionComplete;
  final Function()? onAllCompleted;

  const DailyMissionsFlowScreen({
    super.key,
    required this.missions,
    required this.initialMissionIndex,
    required this.provider,
    required this.missionsController,
    required this.dailyProgressService,
    required this.spiritualStatsService,
    required this.onMissionComplete,
    this.onAllCompleted,
  });

  @override
  State<DailyMissionsFlowScreen> createState() =>
      _DailyMissionsFlowScreenState();
}

class _DailyMissionsFlowScreenState extends State<DailyMissionsFlowScreen> {
  late PageController _pageController;
  late int _currentPageIndex;
  final Map<int, bool> _completedMissions = {};
  bool _allCompletedNotified = false;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialMissionIndex.clamp(
      0,
      widget.missions.length - 1,
    );
    _pageController = PageController(initialPage: _currentPageIndex);

    // Inicializar estado de completado
    for (int i = 0; i < widget.missions.length; i++) {
      _completedMissions[i] = widget.missions[i].completed;
    }

    // Cargar progreso desde Firestore al iniciar
    _loadProgressFromFirestore();
  }

  /// Carga el progreso diario desde Firestore y actualiza el estado
  Future<void> _loadProgressFromFirestore() async {
    try {
      final progress = await widget.dailyProgressService.getTodayProgress();
      if (!mounted) return;

      // Actualizar estado de misiones basado en Firestore
      for (int i = 0; i < widget.missions.length; i++) {
        final mission = widget.missions[i];
        final internalId = DailyProgressService.mapMissionIdToInternal(
          mission.id,
        );
        final isDone = progress.isMissionDone(internalId);
        _completedMissions[i] = isDone;
        if (isDone && !mission.completed) {
          widget.missionsController.completeMission(mission.id);
        }
      }
      _allCompletedNotified = widget.missionsController.isAllCompleted();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[DailyMissionsFlowScreen] Error loading progress: $e');
    }
  }

  /// Verifica si la oración de la noche está disponible (después de las 7 PM)
  bool _isNightPrayerAvailable() {
    final now = DateTime.now();
    return now.hour >= 19; // 7 PM = 19:00
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _getProgress() {
    final essentialIndexes = <int>[
      for (var i = 0; i < widget.missions.length; i++)
        if (!widget.missions[i].isOptional) i,
    ];
    final total = essentialIndexes.length;
    final completed = essentialIndexes
        .where((index) => _completedMissions[index] == true)
        .length;
    if (total == 0) return 0.0;
    return completed / total;
  }

  /// Limpia las etiquetas Strong del texto del versículo
  String _cleanVerseText(String text) {
    // Remover etiquetas strong="GXXXX" o strong='GXXXX'
    var cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'strong="[^"]+"'), '');
    cleaned = cleaned.replaceAll(RegExp(r"strong='[^']+'"), '');
    // Remover cualquier carácter residual de las etiquetas
    cleaned = cleaned.replaceAll(
      RegExp(r'\|\s*'),
      ' ',
    ); // Limpiar pipes residuales
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' '); // Normalizar espacios
    return cleaned.trim();
  }

  String _getMissionContent(String id) {
    switch (id) {
      case 'verse':
        final verseText =
            widget.provider.todayVerse?.text ??
            'Versículo del día no disponible por el momento.';
        // Limpiar etiquetas Strong del versículo
        return _cleanVerseText(verseText);
      case 'morning':
        return widget.provider.todayMorningPrayer?.text ??
            'Oración del día no disponible por el momento.';
      case 'night':
        return widget.provider.todayEveningPrayer?.text ??
            'Oración de la noche no disponible por el momento.';
      case 'practice':
        return widget.missions
                .where((mission) => mission.id == id)
                .firstOrNull
                ?.content ??
            'Haz una pausa y convierte la Palabra de hoy en un gesto concreto.';
      case 'family':
        return widget.provider.todayFamilyPrayer?.text ??
            'Señor, bendice a mi familia, cuida su salud y guíanos en amor. Amén.';
      default:
        return 'Contenido no disponible.';
    }
  }

  String? _getMissionReference(String id) {
    switch (id) {
      case 'verse':
        return widget.provider.todayVerse?.reference;
      default:
        return null;
    }
  }

  void _handleNext() {
    final currentMission = widget.missions[_currentPageIndex];
    if (!(_completedMissions[_currentPageIndex] ?? false)) {
      _completeCurrentMission();
    }

    // El cierre nocturno nunca se encadena a los tres momentos esenciales.
    if (currentMission.isOptional ||
        widget.missionsController.isAllCompleted()) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    for (
      var index = _currentPageIndex + 1;
      index < widget.missions.length;
      index++
    ) {
      if (!widget.missions[index].isOptional) {
        setState(() => _currentPageIndex = index);
        return;
      }
    }
    Navigator.of(context).pop();
  }

  void _completeCurrentMission() {
    final mission = widget.missions[_currentPageIndex];
    if (_completedMissions[_currentPageIndex] == true) return;
    if (mission.id == 'night' && !_isNightPrayerAvailable()) return;

    _completedMissions[_currentPageIndex] = true;
    widget.missionsController.completeMission(mission.id);
    widget.onMissionComplete(mission);
    final isFirst = widget.missionsController.completedEssentialCount == 1;
    _saveMissionProgressAsync(mission, isFirstMission: isFirst);

    if (!mission.isOptional &&
        widget.missionsController.isAllCompleted() &&
        !_allCompletedNotified) {
      _allCompletedNotified = true;
      widget.onAllCompleted?.call();
    }
    if (mounted) setState(() {});
  }

  /// Guarda el progreso de la misión en segundo plano sin bloquear la UI
  void _saveMissionProgressAsync(
    Mission mission, {
    bool isFirstMission = false,
  }) {
    // Ejecutar en segundo plano sin bloquear la navegación
    Future.microtask(() async {
      try {
        final internalId = DailyProgressService.mapMissionIdToInternal(
          mission.id,
        );
        debugPrint(
          '[DailyMissionsFlowScreen] 📝 Mission ID: ${mission.id} -> Internal ID: $internalId',
        );

        // Guardar en Firestore primero (más rápido)
        await widget.dailyProgressService.setMissionDone(
          internalId,
          done: true,
          requiredMissionIds: widget.missions
              .where((item) => !item.isOptional)
              .map(
                (item) => DailyProgressService.mapMissionIdToInternal(item.id),
              )
              .toList(),
        );
        debugPrint(
          '[DailyMissionsFlowScreen] ✅ Mission saved to Firestore: $internalId',
        );

        // NO marcar día activo al completar misiones individuales
        // La racha se actualiza al completar los tres momentos esenciales.
        // (esto se hace en HomeScreen.onAllCompleted)

        // Incrementar contadores según el tipo de misión
        // Esperar a que termine para asegurar que se actualice correctamente
        try {
          debugPrint(
            '[DailyMissionsFlowScreen] 🔍 Checking mission type: $internalId (original: ${mission.id})',
          );
          if (internalId == 'verse_of_day') {
            debugPrint(
              '[DailyMissionsFlowScreen] 📖 Detected verse mission, calling incrementVerseRead...',
            );
            try {
              await widget.spiritualStatsService.incrementVerseRead();
              debugPrint(
                '[DailyMissionsFlowScreen] ✅ Verse read incremented successfully',
              );
            } catch (e) {
              debugPrint(
                '[DailyMissionsFlowScreen] ❌ Failed to increment verse read: $e',
              );
              // Continuar sin romper el flujo
            }
          } else if (internalId == 'prayer_day' ||
              internalId == 'prayer_night' ||
              internalId == 'pray_family') {
            debugPrint(
              '[DailyMissionsFlowScreen] 🙏 Detected prayer mission ($internalId), calling incrementPrayerCompleted...',
            );
            try {
              await widget.spiritualStatsService.incrementPrayerCompleted();
              debugPrint(
                '[DailyMissionsFlowScreen] ✅ Prayer completed incremented successfully',
              );
            } catch (e) {
              debugPrint(
                '[DailyMissionsFlowScreen] ❌ Failed to increment prayer completed: $e',
              );
              // Continuar sin romper el flujo
            }
          } else {
            debugPrint(
              '[DailyMissionsFlowScreen] ⚠️ Unknown mission type: $internalId (mission.id: ${mission.id})',
            );
          }
        } catch (e, stackTrace) {
          debugPrint(
            '[DailyMissionsFlowScreen] ❌ Error incrementing stats: $e',
          );
          debugPrint('[DailyMissionsFlowScreen] Stack trace: $stackTrace');
          // No re-lanzar para no romper el flujo, pero loguear bien
        }
      } catch (e) {
        debugPrint(
          '[DailyMissionsFlowScreen] ❌ Error saving mission progress: $e',
        );
      }
    });
  }

  void _share() {
    final currentMission = widget.missions[_currentPageIndex];
    final content = _getMissionContent(currentMission.id);
    final reference = _getMissionReference(currentMission.id);

    ShareService.shareAsText(
      text: content,
      reference: reference ?? currentMission.title,
      title: currentMission.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.missions[_currentPageIndex];
    final blocked =
        mission.id == 'night' &&
        !_isNightPrayerAvailable() &&
        !(_completedMissions[_currentPageIndex] ?? false);
    return PrayerReadingExperience(
      provenance: mission.id == 'verse'
          ? ContentProvenance.bible
          : const {'morning', 'night', 'family'}.contains(mission.id)
          ? ContentProvenance.aiGenerated
          : ContentProvenance.unverified,
      key: ValueKey('daily_${mission.id}'),
      loading: false,
      error: blocked
          ? 'Esta oración estará disponible a las 7:00 PM. Vuelve más tarde para cerrar el día en paz.'
          : null,
      category: mission.isOptional
          ? 'Cierre opcional'
          : 'Momento ${widget.missions.take(_currentPageIndex + 1).where((m) => !m.isOptional).length} de ${widget.missions.where((m) => !m.isOptional).length}',
      title: mission.title,
      text: blocked ? null : _getMissionContent(mission.id),
      verseReference: blocked ? null : _getMissionReference(mission.id),
      accent: _missionAccent(mission.id),
      onBack: () => Navigator.of(context).pop(),
      onShare: blocked ? null : _share,
      onComplete: blocked ? null : _completeCurrentMission,
      onNext: blocked ? null : _handleNext,
      initiallyCompleted: mission.completed,
      primaryActionLabel: mission.id == 'practice'
          ? 'He realizado este gesto'
          : mission.id == 'verse'
          ? 'He recibido la Palabra'
          : mission.id == 'night'
          ? 'He cerrado mi día en oración'
          : 'He terminado mi oración',
      completedActionLabel:
          mission.isOptional ||
              (mission.id == 'practice' &&
                  widget.missionsController.isAllCompleted())
          ? 'Finalizar'
          : 'Continuar',
    );
  }

  Color _missionAccent(String id) {
    switch (id) {
      case 'morning':
        return const Color(0xFFB58A45);
      case 'night':
        return const Color(0xFF536C91);
      case 'practice':
        return const Color(0xFF5F8178);
      default:
        return const Color(0xFF77649A);
    }
  }

  // Conservado temporalmente como referencia de la composición anterior.
  // ignore: unused_element
  Widget _buildLegacy(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1C2A), Color(0xFF2D2347)],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar con progreso
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                        ),
                        onPressed: _share,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Progress today',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(_getProgress().clamp(0.0, 1.0) * 100).round()}%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _getProgress().clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFB74D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // PageView con las misiones
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Solo avance con botones
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    itemCount: widget.missions.length,
                    itemBuilder: (context, index) {
                      final mission = widget.missions[index];
                      final isBlocked =
                          mission.id == 'night' &&
                          !_isNightPrayerAvailable() &&
                          !(_completedMissions[index] ?? false);
                      return _MissionStepWidget(
                        key: ValueKey(mission.id),
                        mission: mission,
                        content: isBlocked
                            ? ''
                            : _getMissionContent(mission.id),
                        reference: isBlocked
                            ? null
                            : _getMissionReference(mission.id),
                        isBlocked: isBlocked,
                      );
                    },
                  ),
                ),
                // Botón de acción
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: _primaryNextButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryNextButton() {
    // Verificar si todos los momentos esenciales están completados.
    final allCompleted = widget.missionsController.isAllCompleted();
    final isLastMission = _currentPageIndex + 1 >= widget.missions.length;
    final currentMission = widget.missions[_currentPageIndex];
    final isCurrentBlocked =
        currentMission.id == 'night' &&
        !_isNightPrayerAvailable() &&
        !(_completedMissions[_currentPageIndex] ?? false);

    // Mostrar "Cerrar" si es la última misión (completadas o no) o si todas están completadas
    final showClose = isLastMission || allCompleted;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isCurrentBlocked ? null : _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentBlocked
              ? Colors.grey.withValues(alpha: 0.5)
              : const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              showClose ? 'Cerrar' : 'Siguiente',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Icon(
              showClose ? Icons.close_rounded : Icons.arrow_forward_rounded,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizable para cada paso/misión dentro del PageView
class _MissionStepWidget extends StatefulWidget {
  final Mission mission;
  final String content;
  final String? reference;
  final bool isBlocked;

  const _MissionStepWidget({
    super.key,
    required this.mission,
    required this.content,
    this.reference,
    this.isBlocked = false,
  });

  @override
  State<_MissionStepWidget> createState() => _MissionStepWidgetState();
}

class _MissionStepWidgetState extends State<_MissionStepWidget>
    with AutomaticKeepAliveClientMixin {
  bool _fadeIn = false;

  @override
  bool get wantKeepAlive => true; // Mantener estado entre páginas

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        setState(() => _fadeIn = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: _fadeIn ? 1.0 : 0.0,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Text(
              widget.mission.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.isBlocked)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Esta misión estará disponible a las 7:00 PM',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vuelve más tarde para completar tu oración de la noche',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                widget.content,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.reference != null && widget.reference!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  widget.reference!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFB74D),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
