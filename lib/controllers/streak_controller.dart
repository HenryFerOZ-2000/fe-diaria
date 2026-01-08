import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isInitialLoad = true; // Flag para saber si es la primera carga
  static const String _lastPopupStreakKey = 'last_popup_streak';
  static const String _lastPopupDateKey = 'last_popup_date';

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
  /// Si forceUpdate es true, no se considera como carga inicial (para permitir popup)
  void reloadFromFirestore({bool forceUpdate = false}) {
    if (forceUpdate) {
      // Si es una actualización forzada (después de completar misiones),
      // NO resetear _isInitialLoad para permitir que se muestre el popup
      debugPrint('[StreakController] 🔄 Force reload from Firestore (will allow popup)');
      _isInitialLoad = false; // Asegurar que no se considere como carga inicial
    }
    _loadFromFirestore(forceUpdate: forceUpdate);
  }

  void _loadFromFirestore({bool forceUpdate = false}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Si no hay usuario, usar valores por defecto
      debugPrint('[StreakController] No user authenticated, using default values');
      totalDays = 0;
      notifyListeners();
      return;
    }

    debugPrint('[StreakController] Loading streak from Firestore for uid=$uid (forceUpdate=$forceUpdate)');

    // Cancelar suscripción anterior si existe
    _statsSubscription?.cancel();

    // Solo marcar como carga inicial si NO es una actualización forzada
    if (!forceUpdate) {
      _isInitialLoad = true;
    }

    // Cargar inicialmente para asegurar que tenemos datos inmediatos
    _spiritualStatsService.getStats().then((stats) {
      final previousTotal = totalDays;
      debugPrint('[StreakController] Initial stats loaded: currentStreak=${stats.currentStreak}, previousTotal=$previousTotal, bestStreak=${stats.bestStreak}, isInitialLoad=$_isInitialLoad');
      _updateFromStats(stats, isInitialLoad: _isInitialLoad);
      
      // Si es una actualización forzada y la racha aumentó, mostrar popup
      if (forceUpdate && totalDays > previousTotal) {
        debugPrint('[StreakController] 🔥 Force update detected streak increase: $previousTotal -> $totalDays');
        _checkAndShowPopup(previousTotal, totalDays);
      }
      
      // Marcar que ya no es la carga inicial después de cargar
      if (_isInitialLoad) {
        _isInitialLoad = false;
      }
    }).catchError((e) {
      debugPrint('[StreakController] Error loading initial stats: $e');
      _isInitialLoad = false;
    });

    // Suscribirse a cambios en tiempo real (para recibir actualizaciones)
    _statsSubscription = _spiritualStatsService.statsStream().listen((stats) {
      final previousTotal = totalDays;
      debugPrint('[StreakController] ⚡ Stats updated from stream: currentStreak=${stats.currentStreak}, previousTotal=$previousTotal, bestStreak=${stats.bestStreak}, isInitialLoad=$_isInitialLoad');
      _updateFromStats(stats, isInitialLoad: _isInitialLoad);
      
      // Solo mostrar popup si:
      // 1. NO es la carga inicial
      // 2. La racha realmente aumentó
      // 3. No se mostró ya el popup para este incremento hoy
      if (!_isInitialLoad && totalDays > previousTotal) {
        debugPrint('[StreakController] 🔥 Stream detected streak increase: $previousTotal -> $totalDays');
        _checkAndShowPopup(previousTotal, totalDays);
      }
      
      // Marcar que ya no es la carga inicial después del primer update del stream
      if (_isInitialLoad) {
        _isInitialLoad = false;
      }
    }, onError: (e) {
      debugPrint('[StreakController] ❌ Error in stats stream: $e');
      _isInitialLoad = false;
    });
  }

  void _updateFromStats(SpiritualStats stats, {bool isInitialLoad = false}) {
    final newTotalDays = stats.currentStreak;
    final changed = totalDays != newTotalDays;
    
    if (changed) {
      debugPrint('[StreakController] 🔄 Updating totalDays from $totalDays to $newTotalDays (isInitialLoad=$isInitialLoad)');
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

  /// Verifica si se debe mostrar el popup y lo muestra solo si no se mostró ya hoy
  Future<void> _checkAndShowPopup(int previousTotal, int newTotal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayDateString();
      final lastPopupDate = prefs.getString(_lastPopupDateKey);
      final lastPopupStreak = prefs.getInt(_lastPopupStreakKey) ?? 0;
      
      // Solo mostrar popup si:
      // 1. No se mostró popup hoy, O
      // 2. Se mostró popup hoy pero para una racha diferente (menor)
      final shouldShow = lastPopupDate != today || lastPopupStreak < newTotal;
      
      if (shouldShow) {
        debugPrint('[StreakController] 🔥 Streak increased from $previousTotal to $newTotal, showing popup (lastPopupDate=$lastPopupDate, lastPopupStreak=$lastPopupStreak)');
        
        // Guardar que se mostró el popup para esta racha hoy
        await prefs.setString(_lastPopupDateKey, today);
        await prefs.setInt(_lastPopupStreakKey, newTotal);
        
        _triggerAnimation();
        showPopup = true;
        notifyListeners();
      } else {
        debugPrint('[StreakController] ⏭️ Skipping popup: already shown today for streak $newTotal (lastPopupDate=$lastPopupDate, lastPopupStreak=$lastPopupStreak)');
      }
    } catch (e) {
      debugPrint('[StreakController] ❌ Error checking popup: $e');
      // En caso de error, mostrar el popup de todas formas
      _triggerAnimation();
      showPopup = true;
      notifyListeners();
    }
  }

  String _getTodayDateString() {
    // Usar la fecha LOCAL del dispositivo
    final now = DateTime.now(); // Fecha local del dispositivo
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    debugPrint('[StreakController] 📅 Today date string (local): $y-$m-$d (device timezone)');
    return '$y-$m-$d';
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

