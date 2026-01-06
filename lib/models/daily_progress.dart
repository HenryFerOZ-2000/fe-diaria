/// Modelo para progreso diario de misiones
/// Lee de users/{uid}/dailyProgress/{dateId} donde dateId = "YYYY-MM-DD"
class DailyProgress {
  final String dateId; // "YYYY-MM-DD"
  final Map<String, bool> missions; // missionId: true/false
  final double progressPercent; // 0.0 - 100.0
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyProgress({
    required this.dateId,
    required this.missions,
    required this.progressPercent,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyProgress.fromFirestore(String dateId, Map<String, dynamic> data) {
    final missionsMap = Map<String, bool>.from(data['missions'] ?? {});
    final progressPercent = (data['progressPercent'] ?? 0.0) as double;
    
    DateTime? createdAt;
    DateTime? updatedAt;
    
    if (data['createdAt'] != null) {
      final ts = data['createdAt'];
      if (ts is DateTime) {
        createdAt = ts;
      } else if (ts is Map && ts['_seconds'] != null) {
        createdAt = DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000);
      }
    }
    
    if (data['updatedAt'] != null) {
      final ts = data['updatedAt'];
      if (ts is DateTime) {
        updatedAt = ts;
      } else if (ts is Map && ts['_seconds'] != null) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000);
      }
    }

    return DailyProgress(
      dateId: dateId,
      missions: missionsMap,
      progressPercent: progressPercent,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory DailyProgress.empty(String dateId) {
    return DailyProgress(
      dateId: dateId,
      missions: const {},
      progressPercent: 0.0,
    );
  }

  bool isMissionDone(String missionId) => missions[missionId] == true;
  
  int get completedCount => missions.values.where((done) => done == true).length;
}

