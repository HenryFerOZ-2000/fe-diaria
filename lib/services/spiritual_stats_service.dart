import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/spiritual_stats.dart';
import 'streak_service.dart';
import 'storage_service.dart';

class SpiritualStatsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  late final StreakService _streakService;

  SpiritualStatsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StreakService? streakService,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _streakService = streakService ?? StreakService(
      storageService ?? StorageService(),
    );
  }

  /// Obtiene las estadísticas espirituales del usuario actual
  /// Prioriza datos de Firestore, calcula si no existen
  Future<SpiritualStats> getStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return SpiritualStats.empty();
    }

    try {
      // Intentar obtener de Firestore (si existe doc dedicado o en users/{uid})
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        
        // Si hay stats dedicadas, usarlas
        if (data.containsKey('spiritualStats')) {
          final statsData = data['spiritualStats'] as Map<String, dynamic>?;
          if (statsData != null) {
            return SpiritualStats.fromFirestore(statsData);
          }
        }
        
        // Si no, calcular desde datos existentes
        return await _calculateStats(uid, data);
      }
      
      // Si no existe el doc, calcular desde cero
      return await _calculateStats(uid, {});
    } catch (e) {
      debugPrint('[SpiritualStatsService] Error getting stats: $e');
      return SpiritualStats.empty();
    }
  }

  /// Calcula estadísticas desde Firestore (sin queries pesadas)
  /// TODO: En el futuro, esto debería actualizarse en tiempo real cuando ocurren eventos
  Future<SpiritualStats> _calculateStats(String uid, Map<String, dynamic> userData) async {
    try {
      // Obtener streak
      final streakState = await _streakService.getStreak();
      
      // Contar posts creados (ligero: solo contar docs)
      int postsCount = 0;
      try {
        final postsSnapshot = await _firestore
            .collection('live_posts')
            .where('authorUid', isEqualTo: uid)
            .count()
            .get();
        postsCount = postsSnapshot.count ?? 0;
      } catch (e) {
        debugPrint('[SpiritualStatsService] Error counting posts: $e');
      }

      // Por ahora, usar placeholders para versículos y oraciones
      // TODO: Implementar tracking real cuando se lea un versículo o complete una oración
      final versesRead = (userData['versesRead'] ?? 0) as int;
      final prayersCompleted = (userData['prayersCompleted'] ?? 0) as int;
      
      // Calcular días activos últimos 30 días (simplificado: basado en streak)
      // TODO: Implementar tracking real de días activos
      final activeDaysLast30 = streakState.current >= 30 ? 30 : streakState.current;

      return SpiritualStats(
        activeDaysLast30: activeDaysLast30,
        prayersCompleted: prayersCompleted,
        versesRead: versesRead,
        postsCreated: postsCount,
        currentStreak: streakState.current,
        bestStreak: streakState.best,
      );
    } catch (e) {
      debugPrint('[SpiritualStatsService] Error calculating stats: $e');
      return SpiritualStats.empty();
    }
  }

  /// Stream de estadísticas (para actualizaciones en tiempo real)
  Stream<SpiritualStats> statsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(SpiritualStats.empty());
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) {
        return await _calculateStats(uid, {});
      }
      final data = snapshot.data() ?? {};
      return await _calculateStats(uid, data);
    });
  }
}

