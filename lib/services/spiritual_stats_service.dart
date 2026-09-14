import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/spiritual_stats.dart';

/// Servicio para gestionar estadísticas espirituales
/// Lee de users/{uid}/spiritualStats/main
class SpiritualStatsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  static const String _lastMarkActiveDateKey = 'lastMarkActiveDate';

  SpiritualStatsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Marca el día actual como activo (llama a Cloud Function)
  /// La función es idempotente, así que puede llamarse múltiples veces sin problema
  /// Solo evita llamadas duplicadas en la misma sesión usando SharedPreferences
  Future<void> markActiveTodayOncePerDay({bool force = false}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint(
        '[SpiritualStatsService] markActiveTodayOncePerDay: No user authenticated',
      );
      return;
    }

    final today = _getTodayDateString();

    if (!force) {
      // Verificar si ya se llamó hoy (solo para evitar spam, pero la función es idempotente)
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(_lastMarkActiveDateKey);

      if (lastDate == today) {
        debugPrint(
          '[SpiritualStatsService] markActiveTodayOncePerDay: Already called today ($today), skipping (function is idempotent)',
        );
        // Aún así, verificar que el documento existe en Firestore
        // Si no existe, forzar la llamada
        try {
          final statsDoc = await _firestore
              .collection('users')
              .doc(uid)
              .collection('spiritualStats')
              .doc('main')
              .get();
          if (!statsDoc.exists) {
            debugPrint(
              '[SpiritualStatsService] Document does not exist, forcing call',
            );
            force = true;
          }
        } catch (e) {
          debugPrint('[SpiritualStatsService] Error checking document: $e');
        }

        if (!force) {
          return;
        }
      }
    }

    try {
      debugPrint(
        '[SpiritualStatsService] markActiveTodayOncePerDay: Calling function for uid=$uid, today=$today, force=$force',
      );
      final callable = _functions.httpsCallable('markActiveToday');
      final result = await callable.call();

      // Guardar que se llamó hoy
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastMarkActiveDateKey, today);

      debugPrint(
        '[SpiritualStatsService] markActiveTodayOncePerDay: ✅ Success! Result: ${result.data}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[SpiritualStatsService] ❌ ERROR calling markActiveTodayOncePerDay: $e',
      );
      debugPrint('[SpiritualStatsService] Error type: ${e.runtimeType}');
      if (e is FirebaseFunctionsException) {
        debugPrint(
          '[SpiritualStatsService] Firebase error code: ${e.code}, message: ${e.message}',
        );
        debugPrint(
          '[SpiritualStatsService] Firebase error details: ${e.details}',
        );
      }
      debugPrint('[SpiritualStatsService] Stack trace: $stackTrace');
      // No re-lanzar para no romper el flujo, pero loguear bien
    }
  }

  String _getTodayDateString() {
    // Usar la fecha LOCAL del dispositivo, no UTC
    // Esto asegura que la racha se actualice según la hora del celular del usuario
    final now = DateTime.now(); // Fecha local del dispositivo
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    debugPrint(
      '[SpiritualStatsService] 📅 Today date string (local): $year-$month-$day (device timezone)',
    );
    return '$year-$month-$day';
  }

  /// Obtiene las estadísticas espirituales del usuario actual
  /// Lee del documento users/{uid}/spiritualStats/main
  Future<SpiritualStats> getStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('[SpiritualStatsService] getStats: No user authenticated');
      return SpiritualStats.empty();
    }

    try {
      debugPrint('[SpiritualStatsService] getStats: Fetching for uid=$uid');
      final statsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('spiritualStats')
          .doc('main')
          .get();

      if (statsDoc.exists && statsDoc.data() != null) {
        final data = statsDoc.data()!;
        final stats = SpiritualStats.fromFirestore(data);
        debugPrint(
          '[SpiritualStatsService] getStats: Found document - currentStreak=${stats.currentStreak}, bestStreak=${stats.bestStreak}',
        );
        return stats;
      }

      debugPrint('[SpiritualStatsService] getStats: Document does not exist');
      return SpiritualStats.empty();
    } catch (e) {
      debugPrint('[SpiritualStatsService] ❌ Error getting stats: $e');
      return SpiritualStats.empty();
    }
  }

  /// Incrementa el contador de versículos leídos
  Future<void> incrementVerseRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint(
        '[SpiritualStatsService] incrementVerseRead: No user authenticated',
      );
      return;
    }

    try {
      debugPrint(
        '[SpiritualStatsService] 📖 incrementVerseRead: Starting for uid=$uid',
      );
      final callable = _functions.httpsCallable('incrementVerseRead');
      debugPrint(
        '[SpiritualStatsService] 📖 incrementVerseRead: Callable created, calling...',
      );
      final result = await callable.call();
      debugPrint(
        '[SpiritualStatsService] 📖 incrementVerseRead: ✅ Success! Result: ${result.data}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[SpiritualStatsService] ❌ ERROR calling incrementVerseRead: $e',
      );
      debugPrint('[SpiritualStatsService] Error type: ${e.runtimeType}');
      if (e is FirebaseFunctionsException) {
        debugPrint(
          '[SpiritualStatsService] Firebase error code: ${e.code}, message: ${e.message}',
        );
        debugPrint(
          '[SpiritualStatsService] Firebase error details: ${e.details}',
        );
      }
      debugPrint('[SpiritualStatsService] Stack trace: $stackTrace');
      // No re-lanzar para no romper el flujo, pero loguear bien
    }
  }

  /// Incrementa el contador de oraciones completadas
  Future<void> incrementPrayerCompleted() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint(
        '[SpiritualStatsService] incrementPrayerCompleted: No user authenticated',
      );
      return;
    }

    try {
      debugPrint(
        '[SpiritualStatsService] incrementPrayerCompleted: Calling function for uid=$uid',
      );
      final callable = _functions.httpsCallable('incrementPrayerCompleted');
      await callable.call();
      debugPrint(
        '[SpiritualStatsService] incrementPrayerCompleted: ✅ Success!',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[SpiritualStatsService] ❌ ERROR calling incrementPrayerCompleted: $e',
      );
      if (e is FirebaseFunctionsException) {
        debugPrint(
          '[SpiritualStatsService] Firebase error code: ${e.code}, message: ${e.message}',
        );
      }
      debugPrint('[SpiritualStatsService] Stack trace: $stackTrace');
    }
  }

  /// Incrementa el contador de publicaciones creadas
  Future<void> incrementPostCreated() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint(
        '[SpiritualStatsService] incrementPostCreated: No user authenticated',
      );
      return;
    }

    try {
      debugPrint(
        '[SpiritualStatsService] incrementPostCreated: Calling function for uid=$uid',
      );
      final callable = _functions.httpsCallable('incrementPostCreated');
      await callable.call();
      debugPrint('[SpiritualStatsService] incrementPostCreated: ✅ Success!');
    } catch (e, stackTrace) {
      debugPrint(
        '[SpiritualStatsService] ❌ ERROR calling incrementPostCreated: $e',
      );
      if (e is FirebaseFunctionsException) {
        debugPrint(
          '[SpiritualStatsService] Firebase error code: ${e.code}, message: ${e.message}',
        );
      }
      debugPrint('[SpiritualStatsService] Stack trace: $stackTrace');
    }
  }

  /// Incrementa la racha cuando se completan todas las misiones del día
  /// Esta función asegura que la racha se incremente correctamente
  Future<void> completeAllMissions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint(
        '[SpiritualStatsService] completeAllMissions: No user authenticated',
      );
      return;
    }

    try {
      // Enviar la fecha local del dispositivo a la Cloud Function
      // para asegurar consistencia con la fecha del cliente
      final todayDateId = _getTodayDateString();
      debugPrint(
        '[SpiritualStatsService] completeAllMissions: Calling function for uid=$uid with dateId=$todayDateId',
      );
      final callable = _functions.httpsCallable('completeAllMissions');
      final result = await callable.call({'dateId': todayDateId});
      debugPrint(
        '[SpiritualStatsService] completeAllMissions: ✅ Success! Result: ${result.data}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[SpiritualStatsService] ❌ ERROR calling completeAllMissions: $e',
      );
      debugPrint('[SpiritualStatsService] Error type: ${e.runtimeType}');
      if (e is FirebaseFunctionsException) {
        debugPrint(
          '[SpiritualStatsService] Firebase error code: ${e.code}, message: ${e.message}',
        );
        debugPrint(
          '[SpiritualStatsService] Firebase error details: ${e.details}',
        );
      }
      debugPrint('[SpiritualStatsService] Stack trace: $stackTrace');
      // No re-lanzar para no romper el flujo
    }
  }

  /// Stream de estadísticas (para actualizaciones en tiempo real)
  /// Lee del documento users/{uid}/spiritualStats/main
  Stream<SpiritualStats> statsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint(
        '[SpiritualStatsService] statsStream: No user authenticated, returning empty stream',
      );
      return Stream.value(SpiritualStats.empty());
    }

    debugPrint(
      '[SpiritualStatsService] statsStream: Setting up stream for uid=$uid',
    );

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('spiritualStats')
        .doc('main')
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '[SpiritualStatsService] 📊 Stream event: exists=${snapshot.exists}, hasData=${snapshot.data() != null}',
          );

          if (!snapshot.exists || snapshot.data() == null) {
            debugPrint(
              '[SpiritualStatsService] Stream: Document does not exist or has no data',
            );
            return SpiritualStats.empty();
          }

          final data = snapshot.data()!;
          final stats = SpiritualStats.fromFirestore(data);
          debugPrint(
            '[SpiritualStatsService] 📈 Stream: currentStreak=${stats.currentStreak}, bestStreak=${stats.bestStreak}, lastActiveDate=${stats.lastActiveDate}',
          );
          return stats;
        });
  }
}
