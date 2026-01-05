class SpiritualStats {
  final int activeDaysLast30;
  final int prayersCompleted;
  final int versesRead;
  final int postsCreated;
  final int currentStreak;
  final int bestStreak;

  const SpiritualStats({
    required this.activeDaysLast30,
    required this.prayersCompleted,
    required this.versesRead,
    required this.postsCreated,
    required this.currentStreak,
    required this.bestStreak,
  });

  factory SpiritualStats.empty() {
    return const SpiritualStats(
      activeDaysLast30: 0,
      prayersCompleted: 0,
      versesRead: 0,
      postsCreated: 0,
      currentStreak: 0,
      bestStreak: 0,
    );
  }

  factory SpiritualStats.fromFirestore(Map<String, dynamic> data) {
    return SpiritualStats(
      activeDaysLast30: (data['activeDaysLast30'] ?? 0) as int,
      prayersCompleted: (data['prayersCompleted'] ?? 0) as int,
      versesRead: (data['versesRead'] ?? 0) as int,
      postsCreated: (data['postsCreated'] ?? 0) as int,
      currentStreak: (data['currentStreak'] ?? data['streakCurrent'] ?? 0) as int,
      bestStreak: (data['bestStreak'] ?? data['streakBest'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activeDaysLast30': activeDaysLast30,
      'prayersCompleted': prayersCompleted,
      'versesRead': versesRead,
      'postsCreated': postsCreated,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }
}

