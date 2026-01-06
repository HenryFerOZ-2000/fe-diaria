import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/missions_controller.dart';
import '../providers/app_provider.dart';
import 'reading_chat_screen.dart';
import '../services/share_service.dart';
import '../services/daily_progress_service.dart';
import '../services/spiritual_stats_service.dart';

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
  State<DailyMissionsFlowScreen> createState() => _DailyMissionsFlowScreenState();
}

class _DailyMissionsFlowScreenState extends State<DailyMissionsFlowScreen> {
  late PageController _pageController;
  late int _currentPageIndex;
  final Map<int, bool> _completedMissions = {};
  Timer? _autoCompleteTimer;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialMissionIndex.clamp(0, widget.missions.length - 1);
    _pageController = PageController(initialPage: _currentPageIndex);
    
    // Inicializar estado de completado
    for (int i = 0; i < widget.missions.length; i++) {
      _completedMissions[i] = widget.missions[i].completed;
    }
    
    // Cargar progreso desde Firestore al iniciar
    _loadProgressFromFirestore();
    
    // Auto-completar misión actual después de 2 segundos (comportamiento original)
    _startAutoCompleteTimer();
  }
  
  /// Carga el progreso diario desde Firestore y actualiza el estado
  Future<void> _loadProgressFromFirestore() async {
    try {
      final progress = await widget.dailyProgressService.getTodayProgress();
      if (!mounted) return;

      // Actualizar estado de misiones basado en Firestore
      for (int i = 0; i < widget.missions.length; i++) {
        final mission = widget.missions[i];
        final internalId = DailyProgressService.mapMissionIdToInternal(mission.id);
        final isDone = progress.isMissionDone(internalId);
        _completedMissions[i] = isDone;
        if (isDone && !mission.completed) {
          widget.missionsController.completeMission(mission.id);
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[DailyMissionsFlowScreen] Error loading progress: $e');
    }
  }

  void _startAutoCompleteTimer() {
    _autoCompleteTimer?.cancel();
    if (!_completedMissions[_currentPageIndex]!) {
      _autoCompleteTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && !_completedMissions[_currentPageIndex]!) {
          final currentMission = widget.missions[_currentPageIndex];
          _completedMissions[_currentPageIndex] = true;
          widget.missionsController.completeMission(currentMission.id);
          widget.onMissionComplete(currentMission);
          
          // Guardar en Firestore y actualizar stats en segundo plano (sin bloquear UI)
          final isFirst = _completedMissions.values.where((c) => c == true).length == 1;
          _saveMissionProgressAsync(currentMission, isFirstMission: isFirst);
          
          if (widget.missionsController.isAllCompleted() && widget.onAllCompleted != null) {
            widget.onAllCompleted!();
          }
          
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCompleteTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  double _getProgress() {
    final total = widget.missions.length;
    final completed = _completedMissions.values.where((c) => c == true).length;
    if (total == 0) return 0.0;
    return completed / total;
  }

  String _getMissionContent(String id) {
    switch (id) {
      case 'verse':
        return widget.provider.todayVerse?.text ?? 'Versículo del día no disponible por el momento.';
      case 'morning':
        return widget.provider.todayMorningPrayer?.text ?? 'Oración del día no disponible por el momento.';
      case 'night':
        return widget.provider.todayEveningPrayer?.text ?? 'Oración de la noche no disponible por el momento.';
      case 'family':
        return widget.provider.todayFamilyPrayer?.text ?? 'Señor, bendice a mi familia, cuida su salud y guíanos en amor. Amén.';
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
    
    // Marcar como completado si no lo está
    if (!_completedMissions[_currentPageIndex]!) {
      _completedMissions[_currentPageIndex] = true;
      widget.missionsController.completeMission(currentMission.id);
      widget.onMissionComplete(currentMission);
      
      // Guardar en Firestore y actualizar stats en segundo plano (sin bloquear UI)
      final isFirst = _completedMissions.values.where((c) => c == true).length == 1;
      _saveMissionProgressAsync(currentMission, isFirstMission: isFirst);
      
      // Verificar si todas están completadas
      if (widget.missionsController.isAllCompleted() && widget.onAllCompleted != null) {
        widget.onAllCompleted!();
      }
      
      if (mounted) {
        setState(() {}); // Actualizar UI
      }
    }

    // Navegar inmediatamente sin esperar las llamadas asíncronas
    if (_currentPageIndex + 1 < widget.missions.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // Última misión completada - verificar que el contexto sigue montado
      if (mounted && Navigator.of(context).canPop()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Has completado tus misiones de hoy')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// Guarda el progreso de la misión en segundo plano sin bloquear la UI
  void _saveMissionProgressAsync(Mission mission, {bool isFirstMission = false}) {
    // Ejecutar en segundo plano sin bloquear la navegación
    Future.microtask(() async {
      try {
        final internalId = DailyProgressService.mapMissionIdToInternal(mission.id);
        
        // Guardar en Firestore primero (más rápido)
        await widget.dailyProgressService.setMissionDone(
          internalId,
          done: true,
          totalMissions: widget.missions.length,
        );
        
        // Luego actualizar stats (más lento, pero no bloquea)
        // Solo marcar día activo una vez (la primera misión)
        if (isFirstMission) {
          widget.spiritualStatsService.markActiveTodayOncePerDay().catchError((e) {
            debugPrint('[DailyMissionsFlowScreen] Error marking active: $e');
          });
        }
        
        // Incrementar contadores según el tipo de misión
        if (internalId == 'verse_of_day') {
          widget.spiritualStatsService.incrementVerseRead().catchError((e) {
            debugPrint('[DailyMissionsFlowScreen] Error incrementing verse: $e');
          });
        } else if (internalId == 'prayer_day' || 
                   internalId == 'prayer_night' || 
                   internalId == 'pray_family') {
          widget.spiritualStatsService.incrementPrayerCompleted().catchError((e) {
            debugPrint('[DailyMissionsFlowScreen] Error incrementing prayer: $e');
          });
        }
      } catch (e) {
        debugPrint('[DailyMissionsFlowScreen] Error saving mission progress: $e');
      }
    });
  }

  void _openChat() {
    final currentMission = widget.missions[_currentPageIndex];
    final content = _getMissionContent(currentMission.id);
    final reference = _getMissionReference(currentMission.id);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingChatScreen(
          title: currentMission.title,
          content: content,
          reference: reference,
        ),
      ),
    );
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
                colors: [
                  Color(0xFF1E1C2A),
                  Color(0xFF2D2347),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.1),
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white),
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
                              color: Colors.white.withOpacity(0.85),
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
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
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
                    physics: const NeverScrollableScrollPhysics(), // Solo avance con botones
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                      // Reiniciar timer de auto-completado para la nueva página
                      _startAutoCompleteTimer();
                    },
                    itemCount: widget.missions.length,
                    itemBuilder: (context, index) {
                      return _MissionStepWidget(
                        key: ValueKey(widget.missions[index].id),
                        mission: widget.missions[index],
                        content: _getMissionContent(widget.missions[index].id),
                        reference: _getMissionReference(widget.missions[index].id),
                      );
                    },
                  ),
                ),
                // Botones de acción
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _glassButton(
                          icon: Icons.forum_outlined,
                          label: 'Chat',
                          onTap: _openChat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _primaryNextButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, String? label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: EdgeInsets.symmetric(horizontal: label != null ? 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _primaryNextButton() {
    final isLastMission = _currentPageIndex + 1 >= widget.missions.length;
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastMission ? 'Finalizar' : 'Siguiente',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Icon(
              isLastMission ? Icons.check_circle_outline : Icons.arrow_forward_rounded,
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

  const _MissionStepWidget({
    super.key,
    required this.mission,
    required this.content,
    this.reference,
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
        ),
      ),
    );
  }
}

