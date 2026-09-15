import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/spiritual_path.dart';
import 'app_analytics_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class SpiritualPathService {
  static const _activePathKey = 'verbum_active_spiritual_path';
  static const _startedPrefix = 'verbum_spiritual_path_started_';
  static const _completedPrefix = 'verbum_spiritual_path_completed_';
  static const _lastCompletedPrefix = 'verbum_spiritual_path_last_';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SpiritualPathService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> activePathId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_activePathKey);
  }

  Future<SpiritualPathProgress> progressFor(String pathId) async {
    final preferences = await SharedPreferences.getInstance();
    final completed =
        (preferences.getStringList('$_completedPrefix$pathId') ??
                const <String>[])
            .map(int.tryParse)
            .whereType<int>()
            .toSet();
    return SpiritualPathProgress(
      pathId: pathId,
      completedDays: completed,
      startedAt: DateTime.tryParse(
        preferences.getString('$_startedPrefix$pathId') ?? '',
      ),
      lastCompletedAt: DateTime.tryParse(
        preferences.getString('$_lastCompletedPrefix$pathId') ?? '',
      ),
    );
  }

  Future<void> start(String pathId, {String? pathTitle}) async {
    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await preferences.setString(_activePathKey, pathId);
    final firstStart = !preferences.containsKey('$_startedPrefix$pathId');
    if (firstStart) {
      await preferences.setString(
        '$_startedPrefix$pathId',
        now.toIso8601String(),
      );
    }
    await _sync(pathId, startedAt: firstStart ? now : null);
    if (firstStart) {
      await AppAnalyticsService.event(
        'spiritual_path_started',
        parameters: {'path_id': pathId},
      );
      final storage = StorageService();
      if (pathTitle != null && storage.getNotificationEnabled()) {
        final parts = storage.getMorningVerseNotificationTime().split(':');
        final hour = int.tryParse(parts.first) ?? 9;
        final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        await NotificationService().scheduleSpiritualPathReminder(
          pathId: pathId,
          pathTitle: pathTitle,
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  Future<void> completeDay(String pathId, int day, int totalDays) async {
    final preferences = await SharedPreferences.getInstance();
    final current = await progressFor(pathId);
    final completed = {...current.completedDays, day}.toList()..sort();
    final now = DateTime.now();
    await preferences.setStringList(
      '$_completedPrefix$pathId',
      completed.map((value) => '$value').toList(),
    );
    await preferences.setString(
      '$_lastCompletedPrefix$pathId',
      now.toIso8601String(),
    );
    if (completed.length >= totalDays) {
      await preferences.remove(_activePathKey);
      await NotificationService().cancelSpiritualPathReminder();
    } else {
      await preferences.setString(_activePathKey, pathId);
    }
    await _sync(
      pathId,
      completedDays: completed,
      lastCompletedAt: now,
      isComplete: completed.length >= totalDays,
    );
    await AppAnalyticsService.event(
      'spiritual_path_day_completed',
      parameters: {
        'path_id': pathId,
        'day_number': day,
        'path_complete': completed.length >= totalDays ? 1 : 0,
      },
    );
  }

  Future<void> _sync(
    String pathId, {
    DateTime? startedAt,
    List<int>? completedDays,
    DateTime? lastCompletedAt,
    bool? isComplete,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('spiritualPaths')
          .doc(pathId)
          .set({
            'pathId': pathId,
            if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt),
            if (completedDays != null) 'completedDays': completedDays,
            if (lastCompletedAt != null)
              'lastCompletedAt': Timestamp.fromDate(lastCompletedAt),
            if (isComplete != null) 'isComplete': isComplete,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('[SpiritualPathService] sync postponed: $error');
    }
  }
}
