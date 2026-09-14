import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AppAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> event(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('[Analytics] $name skipped: $error');
    }
  }

  static Future<void> setTradition(String tradition) async {
    try {
      await _analytics.setUserProperty(
        name: 'faith_tradition',
        value: tradition,
      );
    } catch (error) {
      debugPrint('[Analytics] user property skipped: $error');
    }
  }
}
