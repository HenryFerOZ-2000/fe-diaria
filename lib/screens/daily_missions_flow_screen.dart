import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import '../controllers/missions_controller.dart';
import '../features/sharing/domain/share_content.dart';
import '../providers/app_provider.dart';
import '../services/share_service.dart';
import '../services/daily_progress_service.dart';
import '../services/spiritual_stats_service.dart';
import '../widgets/prayer_reading_experience.dart';
import '../bible/application/passage_text.dart';

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

  /// Limpia las etiquetas Strong del texto del versículo
  String _cleanVerseText(String text) => sanitizeVerseText(text);

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

    final isScripture = currentMission.id == 'verse';
    ShareService.openComposer(
      context,
      ShareContent(
        title: currentMission.title,
        body: content,
        reference: isScripture && reference != null
            ? '$reference · RV1909'
            : null,
        sourceLabel: isScripture ? 'RV1909' : null,
        kind: isScripture ? ShareContentKind.verse : ShareContentKind.mission,
      ),
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
      nocturne: mission.id == 'night',
      onBack: () => Navigator.of(context).pop(),
      onShare:
          blocked ||
              (mission.id == 'verse' && widget.provider.todayVerse == null)
          ? null
          : _share,
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
}
