/// Progreso de la constancia (racha) hacia el siguiente hito.
final class ConstancyProgress {
  const ConstancyProgress._({
    required this.totalDays,
    required this.nextMilestone,
    required this.previousMilestone,
    required this.progress,
    required this.todayMessage,
  });

  static const milestones = [3, 7, 14, 30, 50, 100, 365];

  factory ConstancyProgress.from({
    required int totalDays,
    required int completedMoments,
    required int totalMoments,
  }) {
    var next = ((totalDays ~/ 365) + 1) * 365;
    for (final milestone in milestones) {
      if (totalDays < milestone) {
        next = milestone;
        break;
      }
    }
    final start = milestones.lastWhere((m) => m < next, orElse: () => 0);
    final span = (next - start).clamp(1, 1 << 30);
    final progress = ((totalDays - start) / span).clamp(0.0, 1.0);

    final remaining = (totalMoments - completedMoments).clamp(0, totalMoments);
    final message = remaining == 0
        ? 'Tu constancia está a salvo hoy'
        : totalDays == 0 && completedMoments == 0
        ? 'Comienza hoy tu recorrido'
        : remaining == 1
        ? '1 momento pendiente para hoy'
        : '$remaining momentos pendientes para hoy';

    return ConstancyProgress._(
      totalDays: totalDays,
      nextMilestone: next,
      previousMilestone: start,
      progress: progress,
      todayMessage: message,
    );
  }

  final int totalDays;
  final int nextMilestone;

  /// Hito ya alcanzado desde el que se mide el avance (0 al empezar).
  final int previousMilestone;

  int get remainingDays => nextMilestone - totalDays;

  /// Avance entre el hito anterior y [nextMilestone], de 0 a 1.
  final double progress;
  final String todayMessage;

  String get daysLabel => totalDays == 1 ? '1 día' : '$totalDays días';
}
