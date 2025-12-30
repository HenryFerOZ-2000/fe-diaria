import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class StreakState {
  final int count;
  final String? lastDateYmd;

  const StreakState({required this.count, required this.lastDateYmd});
}

class StreakService {
  final StorageService _storage;

  StreakService(this._storage);

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

  Future<StreakState> getStreak() async {
    final count = _storage.getStreakCount();
    final last = _storage.getLastStreakDate();
    final lastYmd = last != null ? _toYmd(last.toLocal()) : null;
    debugPrint('[StreakService] getStreak count=$count last=$lastYmd');
    return StreakState(count: count, lastDateYmd: lastYmd);
  }

  Future<StreakState> resetIfNeeded() async {
    final today = _todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));
    final storedCount = _storage.getStreakCount();
    final last = _storage.getLastStreakDate();
    final lastYmd = last != null ? _toYmd(last.toLocal()) : null;

    debugPrint('[StreakService] resetIfNeeded last=$lastYmd count=$storedCount');

    if (last == null) {
      return StreakState(count: storedCount, lastDateYmd: null);
    }

    final todayYmd = _toYmd(today);
    final yesterdayYmd = _toYmd(yesterday);
    final lastIsToday = lastYmd == todayYmd;
    final lastIsYesterday = lastYmd == yesterdayYmd;

    if (lastIsToday || lastIsYesterday) {
      return StreakState(count: storedCount, lastDateYmd: lastYmd);
    }

    await _storage.saveStreakData(streakCount: 0, lastDate: today);
    debugPrint('[StreakService] streak reset to 0 for today=$todayYmd');
    return const StreakState(count: 0, lastDateYmd: null);
  }

  Future<StreakState> recordToday() async {
    final today = _todayLocal();
    final yesterday = today.subtract(const Duration(days: 1));
    final todayYmd = _toYmd(today);
    final last = _storage.getLastStreakDate();
    final lastYmd = last != null ? _toYmd(last.toLocal()) : null;
    var count = _storage.getStreakCount();

    debugPrint('[StreakService] recordToday start count=$count last=$lastYmd');

    if (lastYmd == todayYmd && count > 0) {
      debugPrint('[StreakService] already recorded today');
      return StreakState(count: count, lastDateYmd: todayYmd);
    }

    if (lastYmd == _toYmd(yesterday)) {
      count += 1;
    } else {
      count = 1;
    }

    await _storage.saveStreakData(
      streakCount: count,
      lastDate: today,
    );

    debugPrint('[StreakService] recordToday saved count=$count date=$todayYmd');
    return StreakState(count: count, lastDateYmd: todayYmd);
  }
}

