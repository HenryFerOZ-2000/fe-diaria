/// Modelo para estadísticas espirituales del usuario
/// Lee de users/{uid}/spiritualStats/main
class SpiritualStats {
  final String? lastActiveDate; // "YYYY-MM-DD"
  final int currentStreak;
  final int bestStreak;
  final Map<String, bool> activeDaysMap; // "YYYY-MM-DD": true
  final int prayersCompletedTotal;
  final int versesReadTotal;
  final int postsCreatedTotal;

  const SpiritualStats({
    this.lastActiveDate,
    required this.currentStreak,
    required this.bestStreak,
    this.activeDaysMap = const {},
    required this.prayersCompletedTotal,
    required this.versesReadTotal,
    required this.postsCreatedTotal,
  });

  factory SpiritualStats.fromFirestore(Map<String, dynamic> data) {
    return SpiritualStats(
      lastActiveDate: data['lastActiveDate'] as String?,
      currentStreak: (data['currentStreak'] ?? 0) as int,
      bestStreak: (data['bestStreak'] ?? 0) as int,
      activeDaysMap: Map<String, bool>.from(data['activeDaysMap'] ?? {}),
      prayersCompletedTotal: (data['prayersCompletedTotal'] ?? 0) as int,
      versesReadTotal: (data['versesReadTotal'] ?? 0) as int,
      postsCreatedTotal: (data['postsCreatedTotal'] ?? 0) as int,
    );
  }

  factory SpiritualStats.empty() {
    return const SpiritualStats(
      currentStreak: 0,
      bestStreak: 0,
      prayersCompletedTotal: 0,
      versesReadTotal: 0,
      postsCreatedTotal: 0,
    );
  }

  int get activeDaysLast30 => activeDaysMap.length;

  // Getters de compatibilidad para código existente
  int get versesRead => versesReadTotal;
  int get prayersCompleted => prayersCompletedTotal;
  int get postsCreated => postsCreatedTotal;
}
