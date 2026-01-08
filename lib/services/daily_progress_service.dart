import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/daily_progress.dart';

/// Servicio para gestionar progreso diario de misiones
/// Lee/escribe de users/{uid}/dailyProgress/{dateId}
class DailyProgressService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DailyProgressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String _getTodayDateId() {
    // Usar la fecha LOCAL del dispositivo, no UTC
    // Esto asegura que las misiones se reseteen según la hora del celular del usuario
    final now = DateTime.now(); // Fecha local del dispositivo
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    debugPrint('[DailyProgressService] 📅 Today date ID (local): $year-$month-$day (device timezone)');
    return '$year-$month-$day';
  }

  /// Obtiene el progreso del día actual
  Future<DailyProgress> getTodayProgress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return DailyProgress.empty(_getTodayDateId());
    }

    final dateId = _getTodayDateId();
    try {
      final progressDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyProgress')
          .doc(dateId)
          .get();

      if (progressDoc.exists && progressDoc.data() != null) {
        return DailyProgress.fromFirestore(dateId, progressDoc.data()!);
      }

      return DailyProgress.empty(dateId);
    } catch (e) {
      debugPrint('[DailyProgressService] Error getting today progress: $e');
      return DailyProgress.empty(dateId);
    }
  }

  /// Stream del progreso del día actual (para actualizaciones en tiempo real)
  Stream<DailyProgress> todayProgressStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(DailyProgress.empty(_getTodayDateId()));
    }

    final dateId = _getTodayDateId();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyProgress')
        .doc(dateId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return DailyProgress.empty(dateId);
      }
      return DailyProgress.fromFirestore(dateId, snapshot.data()!);
    });
  }

  /// Marca una misión como completada o no completada
  /// Calcula automáticamente el progressPercent
  Future<void> setMissionDone(String missionId, {bool done = true, int totalMissions = 4}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('[DailyProgressService] setMissionDone: No user authenticated');
      return;
    }

    final dateId = _getTodayDateId();
    try {
      final progressRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('dailyProgress')
          .doc(dateId);

      // Leer el documento actual
      final progressDoc = await progressRef.get();
      final currentData = progressDoc.data() ?? {};
      final currentMissions = Map<String, bool>.from(currentData['missions'] ?? {});

      // Actualizar la misión
      currentMissions[missionId] = done;

      // Calcular progreso
      final completedCount = currentMissions.values.where((d) => d == true).length;
      final progressPercent = (completedCount / totalMissions) * 100.0;

      // Escribir con merge para no sobrescribir otros campos
      final now = Timestamp.now();
      await progressRef.set({
        'missions': currentMissions,
        'progressPercent': progressPercent,
        'updatedAt': now,
        if (!progressDoc.exists) 'createdAt': now,
      }, SetOptions(merge: true));

      debugPrint('[DailyProgressService] setMissionDone: ✅ Mission $missionId = $done, progress = $progressPercent%');
    } catch (e, stackTrace) {
      debugPrint('[DailyProgressService] ❌ ERROR setting mission done: $e');
      debugPrint('[DailyProgressService] Stack trace: $stackTrace');
    }
  }

  /// Mapea IDs de misiones del UI a IDs internos estables
  /// IDs internos: verse_of_day, prayer_day, prayer_night, pray_family
  static String mapMissionIdToInternal(String uiId) {
    switch (uiId) {
      case 'verse':
        return 'verse_of_day';
      case 'morning':
        return 'prayer_day';
      case 'night':
        return 'prayer_night';
      case 'family':
        return 'pray_family';
      default:
        return uiId; // Si no coincide, usar el mismo
    }
  }
}

