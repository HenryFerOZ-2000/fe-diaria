import 'package:flutter/widgets.dart';

import '../../../screens/emotion_passage_read_screen.dart';
import '../../../screens/intention_prayer_read_screen.dart';
import '../../../screens/novena_screen.dart';
import '../../../screens/rosary_guide_screen.dart';
import '../../../screens/traditional_prayer_screen.dart';
import '../../../screens/traditional_prayers_list_screen.dart';
import '../domain/prayer_catalog.dart';

/// Pantalla que abre cada entrada del catálogo.
Widget screenForPrayerEntry(PrayerEntry entry) => switch (entry.destination) {
  PrayerDestination.emotionPassage => EmotionPassageReadScreen(
    emotionKey: entry.key,
  ),
  PrayerDestination.intentionPrayer => IntentionPrayerReadScreen(
    categoryKey: entry.key,
  ),
  PrayerDestination.traditionalPrayer => TraditionalPrayerScreen(
    prayerId: entry.key,
  ),
  PrayerDestination.traditionalList => TraditionalPrayersListScreen(
    religion: 'cristiana',
    category: entry.key,
  ),
  PrayerDestination.rosaryGuide => const RosaryGuideScreen(),
  PrayerDestination.novena => const NovenaScreen(),
};
