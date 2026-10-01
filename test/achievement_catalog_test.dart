import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/models/achievement.dart';
import 'package:verbum/models/spiritual_stats.dart';

void main() {
  SpiritualStats streak(int days) => SpiritualStats(
    currentStreak: days,
    bestStreak: days,
    prayersCompletedTotal: 0,
    versesReadTotal: 0,
    postsCreatedTotal: 0,
  );

  test('catálogo de logros con ids únicos', () {
    final ids = achievementCatalog.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('el logro se desbloquea al alcanzar exactamente la meta', () {
    final streak7 = achievementCatalog.firstWhere((a) => a.id == 'streak_7');
    expect(streak7.isUnlocked(streak(6)), isFalse);
    expect(streak7.isUnlocked(streak(7)), isTrue);
    expect(streak7.getProgress(streak(6)), 6);
  });
}
