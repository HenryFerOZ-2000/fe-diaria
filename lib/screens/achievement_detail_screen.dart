import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement.dart';
import '../models/spiritual_stats.dart';

class AchievementDetailScreen extends StatelessWidget {
  final Achievement achievement;
  final SpiritualStats stats;

  const AchievementDetailScreen({
    super.key,
    required this.achievement,
    required this.stats,
  });

  String _getHowToUnlockText() {
    switch (achievement.type) {
      case AchievementType.streak:
        return 'Mantén una racha de ${achievement.target} días consecutivos';
      case AchievementType.verses:
        return 'Lee ${achievement.target} versículos';
      case AchievementType.prayers:
        return 'Completa ${achievement.target} oraciones';
      case AchievementType.posts:
        return 'Crea ${achievement.target} publicaciones';
    }
  }

  String _getRewardText() {
    // Placeholder: recompensa basada en el tipo de logro
    switch (achievement.type) {
      case AchievementType.streak:
        return '+50 XP';
      case AchievementType.verses:
        return '+30 XP';
      case AchievementType.prayers:
        return '+40 XP';
      case AchievementType.posts:
        return '+20 XP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked(stats);
    final progress = achievement.getProgress(stats);
    final progressPercent = (progress / achievement.target).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalle del logro',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícono grande con Hero animation
            Hero(
              tag: 'achievement_icon_${achievement.id}',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? (isDark
                          ? Colors.amber[900]?.withOpacity(0.3)
                          : Colors.amber[50])
                      : (isDark ? Colors.grey[850] : Colors.grey[100]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? Colors.amber : Colors.grey[300]!,
                    width: isUnlocked ? 3 : 2,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  achievement.icon,
                  size: 64,
                  color: isUnlocked ? Colors.amber[700] : Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              achievement.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Descripción
            Text(
              achievement.description,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Card de estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isUnlocked
                      ? Colors.amber
                      : Colors.grey.withOpacity(0.2),
                  width: isUnlocked ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUnlocked ? Icons.check_circle : Icons.lock,
                        color: isUnlocked ? Colors.amber[700] : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUnlocked ? '¡Logro desbloqueado!' : 'Bloqueado',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked ? Colors.amber[900] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Progreso
                  Text(
                    '$progress / ${achievement.target}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.amber[700] : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUnlocked ? Colors.amber[700]! : Colors.amber[400]!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progressPercent * 100).toStringAsFixed(0)}% completado',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Cómo desbloquear
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cómo desbloquear',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getHowToUnlockText(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Recompensa
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recompensa',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRewardText(),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Fecha de desbloqueo (placeholder)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha de desbloqueo',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUnlocked ? '—' : 'Aún no desbloqueado',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

