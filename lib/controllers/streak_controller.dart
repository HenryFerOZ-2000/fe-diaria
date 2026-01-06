import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/spiritual_stats_service.dart';
import '../models/spiritual_stats.dart';

class StreakDay {
  final String label; // "L", "Ma", ...
  final bool completed;

  const StreakDay({
    required this.label,
    required this.completed,
  });
}

class StreakController extends ChangeNotifier {
  final SpiritualStatsService _spiritualStatsService = SpiritualStatsService();
  StreamSubscription<SpiritualStats>? _statsSubscription;
  
  int totalDays = 0;
  bool playAnimation = false;
  bool showPopup = false;

  List<StreakDay> days = const [
    StreakDay(label: 'L', completed: false),
    StreakDay(label: 'Ma', completed: false),
    StreakDay(label: 'Mi', completed: false),
    StreakDay(label: 'J', completed: false),
    StreakDay(label: 'V', completed: false),
    StreakDay(label: 'S', completed: false),
    StreakDay(label: 'D', completed: false),
  ];

  StreakController() {
    _loadFromFirestore();
  }

  /// Método público para recargar desde Firestore (usado desde HomeScreen)
  void reloadFromFirestore() {
    _loadFromFirestore();
  }

  void _loadFromFirestore() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Si no hay usuario, usar valores por defecto
      debugPrint('[StreakController] No user authenticated, using default values');
      totalDays = 0;
      notifyListeners();
      return;
    }

    debugPrint('[StreakController] Loading streak from Firestore for uid=$uid');

    // Cancelar suscripción anterior si existe
    _statsSubscription?.cancel();

    // Cargar inicialmente para asegurar que tenemos datos inmediatos
    _spiritualStatsService.getStats().then((stats) {
      debugPrint('[StreakController] Initial stats loaded: currentStreak=${stats.currentStreak}, bestStreak=${stats.bestStreak}');
      _updateFromStats(stats);
    }).catchError((e) {
      debugPrint('[StreakController] Error loading initial stats: $e');
    });

    // Suscribirse a cambios en tiempo real (para recibir actualizaciones)
    _statsSubscription = _spiritualStatsService.statsStream().listen((stats) {
      final previousTotal = totalDays;
      debugPrint('[StreakController] ⚡ Stats updated from stream: currentStreak=${stats.currentStreak}, previousTotal=$previousTotal, bestStreak=${stats.bestStreak}');
      _updateFromStats(stats);
      
      // Mostrar popup si la racha aumentó (solo si ya había una racha previa)
      if (totalDays > previousTotal && previousTotal >= 0) {
        debugPrint('[StreakController] 🔥 Streak increased from $previousTotal to $totalDays, showing popup');
        _triggerAnimation();
        showPopup = true;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('[StreakController] ❌ Error in stats stream: $e');
    });
  }

  void _updateFromStats(SpiritualStats stats) {
    final newTotalDays = stats.currentStreak;
    final changed = totalDays != newTotalDays;
    
    if (changed) {
      debugPrint('[StreakController] 🔄 Updating totalDays from $totalDays to $newTotalDays');
      totalDays = newTotalDays;
    }
    
    // Actualizar días de la semana basado en activeDaysMap
    _updateWeekDays(stats.activeDaysMap);
    
    // Siempre notificar listeners para asegurar que la UI se actualice
    notifyListeners();
    
    if (changed) {
      debugPrint('[StreakController] ✅ Notified listeners, totalDays is now $totalDays');
    }
  }

  void _updateWeekDays(Map<String, bool> activeDaysMap) {
    final now = DateTime.now();
    final updated = List<StreakDay>.from(days);
    
    // Calcular el lunes de esta semana (weekday: 1=lunes, 7=domingo)
    // Si hoy es lunes (weekday=1), díasAtrasLunes = 0
    // Si hoy es martes (weekday=2), díasAtrasLunes = 1
    // Si hoy es domingo (weekday=7), díasAtrasLunes = 6
    final weekday = now.weekday; // 1=lunes, 7=domingo
    final diasAtrasLunes = weekday - 1; // 0 para lunes, 6 para domingo
    
    // Calcular los 7 días de la semana actual (lunes a domingo)
    for (int i = 0; i < 7; i++) {
      // i=0 es lunes, i=6 es domingo
      // Calcular la fecha para este día de la semana
      final date = now.subtract(Duration(days: diasAtrasLunes - i));
      final ymd = _toYmd(date);
      
      // Solo marcar como completado si:
      // 1. El día está en activeDaysMap Y
      // 2. El día es hoy o un día pasado (no futuro)
      // Comparar solo la fecha (sin hora) para determinar si es hoy o pasado
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      final isTodayOrPast = dateOnly.isBefore(today) || dateOnly.isAtSameMomentAs(today);
      final completed = isTodayOrPast && activeDaysMap[ymd] == true;
      
      debugPrint('[StreakController] Day $i (${updated[i].label}): date=$ymd, weekday=${date.weekday}, isTodayOrPast=$isTodayOrPast, completed=$completed');
      
      updated[i] = StreakDay(
        label: updated[i].label,
        completed: completed,
      );
    }
    
    days = updated;
  }

  String _toYmd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void completeToday(int index) {
    if (index < 0 || index >= days.length) return;
    // Evitar completar dos veces el mismo día.
    if (days[index].completed) {
      return;
    }
    final updated = List<StreakDay>.from(days);
    updated[index] = StreakDay(label: updated[index].label, completed: true);
    days = updated;
    // No incrementar totalDays aquí - se actualizará desde Firestore
    _triggerAnimation();
    showPopup = true;
    notifyListeners();
  }

  void _triggerAnimation() {
    playAnimation = true;
    notifyListeners();
    Timer(const Duration(seconds: 2), () {
      playAnimation = false;
      notifyListeners();
    });
  }

  void consumePopup() {
    if (!showPopup) return;
    showPopup = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }
}

