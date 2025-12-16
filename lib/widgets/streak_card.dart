import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/streak_controller.dart';

/// Tarjeta de racha reutilizable.
/// Usa los colores existentes del tema; no modifica la paleta global.
class StreakCard extends StatelessWidget {
  final int currentStreak;
  final int goalDays;
  final double progressPercent; // 0.0 - 1.0

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.goalDays,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final progress = progressPercent.clamp(0.0, 1.0);
    const progressColor = Color(0xFF9D7DFF);
    const backgroundColor = Color(0xFF2C243F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$currentStreak días seguidos',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Meta: $goalDays días',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícono de fuego animado.
class FireAnimatedIcon extends StatelessWidget {
  final bool play;

  const FireAnimatedIcon({
    super.key,
    required this.play,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: play ? 1.2 : 1.0,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: play ? 1.0 : 0.85,
        curve: Curves.easeIn,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }
}

/// Fila de días de la semana con check.
class StreakWeekRow extends StatelessWidget {
  final List<StreakDay> days;

  const StreakWeekRow({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final completed = day.completed;
        final circleColor = completed ? Colors.orangeAccent : const Color(0xFF2D2347);
        return Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                border: Border.all(
                  color: completed ? Colors.transparent : Colors.white.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
              child: completed
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 6),
            Text(
              day.label,
              style: GoogleFonts.inter(
                color: const Color(0xFF2C2C2C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Tarjeta de racha estilo Duolingo.
class StreakCardDuolingoStyle extends StatelessWidget {
  final int totalDays;
  final bool playAnimation;
  final List<StreakDay> weekDays;

  const StreakCardDuolingoStyle({
    super.key,
    required this.totalDays,
    required this.playAnimation,
    required this.weekDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE9E9E9),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FireAnimatedIcon(
            play: playAnimation,
          ),
          const SizedBox(height: 6),
          Text(
            '$totalDays días',
            style: GoogleFonts.inter(
              color: const Color(0xFF2C2C2C),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          StreakWeekRow(days: weekDays),
        ],
      ),
    );
  }
}

