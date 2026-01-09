import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class StreakState {
  final int current;
  final int best;
  final String? lastDateYmd;

  const StreakState({
    required this.current,
    required this.best,
    required this.lastDateYmd,
  });
}

/// Streak persistido en Firestore (fuente de verdad) con caché local como fallback.
class StreakService {
  final StorageService _storage;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StreakService(this._storage,
      {FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String _toYmd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _todayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<StreakState> _fromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return _fromCache();
    }
    final data = doc.data() ?? {};
    final current = (data['streakCurrent'] ?? 0) as int;
    final best = (data['streakBest'] ?? current) as int;
    final last = data['lastStreakDate'];
    String? lastYmd;
    if (last is String) {
      lastYmd = last;
    } else if (last is Timestamp) {
      lastYmd = _toYmd(last.toDate());
    }
    return StreakState(current: current, best: best, lastDateYmd: lastYmd);
  }

  StreakState _fromCache() {
    final current = _storage.getStreakCount();
    final last = _storage.getLastStreakDate();
    final lastYmd = last != null ? _toYmd(last.toLocal()) : null;
    // best no se guardaba, usar current como fallback
    return StreakState(current: current, best: current, lastDateYmd: lastYmd);
  }

  Future<void> _persist(String uid, StreakState state, {DateTime? lastDate}) async {
    final data = {
      'streakCurrent': state.current,
      'streakBest': state.best,
      'lastStreakDate': lastDate != null ? _toYmd(lastDate) : state.lastDateYmd,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Obtiene la racha, priorizando Firestore, con fallback en caché local.
  Future<StreakState> getStreak() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return _fromCache();
    try {
      final state = await _fromFirestore(uid);
      return state;
    } catch (e) {
      debugPrint('[StreakService] getStreak fallback cache error=$e');
      return _fromCache();
    }
  }

  Future<StreakState> resetIfNeeded() async {
    final today = _todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));
    final todayYmd = _toYmd(today);
    final yesterdayYmd = _toYmd(yesterday);

    final currentState = await getStreak();
    final lastYmd = currentState.lastDateYmd;
    final best = currentState.best;

    if (lastYmd == null) {
      return currentState;
    }
    if (lastYmd == todayYmd || lastYmd == yesterdayYmd) {
      return currentState;
    }

    final newState = StreakState(current: 0, best: best, lastDateYmd: todayYmd);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _persist(uid, newState, lastDate: today);
    }
    await _storage.saveStreakData(streakCount: 0, lastDate: today);
    return newState;
  }

  Future<StreakState> recordToday() async {
    final today = _todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));
    final todayYmd = _toYmd(today);
    final yesterdayYmd = _toYmd(yesterday);

    var state = await getStreak();
    var current = state.current;
    var best = state.best;
    final lastYmd = state.lastDateYmd;

    if (lastYmd == todayYmd && current > 0) {
      return state;
    }

    if (lastYmd == yesterdayYmd) {
      current += 1;
    } else {
      current = 1;
    }
    if (current > best) best = current;

    state = StreakState(current: current, best: best, lastDateYmd: todayYmd);

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _persist(uid, state, lastDate: today);
    }

    await _storage.saveStreakData(streakCount: current, lastDate: today);
    return state;
  }
}

