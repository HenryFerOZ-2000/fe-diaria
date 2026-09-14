import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/streak_controller.dart';

class FireAnimatedIcon extends StatelessWidget {
  final bool play;
  final double size;

  const FireAnimatedIcon({super.key, required this.play, this.size = 23});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: play ? 1.12 : 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2C477), Color(0xFFC98043)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE6A65E).withValues(alpha: .30),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.local_fire_department_rounded,
          color: const Color(0xFF2A1D31),
          size: size,
        ),
      ),
    );
  }
}

class StreakWeekRow extends StatelessWidget {
  final List<StreakDay> days;

  const StreakWeekRow({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;
    return Row(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final isToday = index == todayIndex;
        return Expanded(
          child: Column(
            children: [
              Text(
                day.label,
                style: GoogleFonts.inter(
                  color: isToday
                      ? Colors.white
                      : Colors.white.withValues(alpha: .52),
                  fontSize: 10.5,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.completed
                      ? const Color(0xFFE7B868)
                      : Colors.white.withValues(alpha: isToday ? .10 : .045),
                  border: Border.all(
                    color: day.completed
                        ? const Color(0xFFF5D79D)
                        : Colors.white.withValues(alpha: isToday ? .65 : .14),
                    width: isToday ? 1.5 : 1,
                  ),
                ),
                child: day.completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF241A2B),
                        size: 15,
                      )
                    : isToday
                    ? Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE7B868),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Tarjeta principal de constancia mostrada en la pantalla Hoy.
class StreakCardDuolingoStyle extends StatelessWidget {
  final int totalDays;
  final bool playAnimation;
  final List<StreakDay> weekDays;
  final int completedMoments;
  final int totalMoments;
  final VoidCallback? onTap;

  const StreakCardDuolingoStyle({
    super.key,
    required this.totalDays,
    required this.playAnimation,
    required this.weekDays,
    this.completedMoments = 0,
    this.totalMoments = 3,
    this.onTap,
  });

  int get _nextMilestone {
    const milestones = [3, 7, 14, 30, 50, 100, 365];
    for (final milestone in milestones) {
      if (totalDays < milestone) return milestone;
    }
    return ((totalDays ~/ 365) + 1) * 365;
  }

  String get _todayMessage {
    final remaining = (totalMoments - completedMoments).clamp(0, totalMoments);
    if (remaining == 0) return 'Tu constancia está a salvo hoy';
    if (totalDays == 0 && completedMoments == 0) {
      return 'Comienza hoy tu recorrido';
    }
    if (remaining == 1) return '1 momento pendiente para hoy';
    return '$remaining momentos pendientes para hoy';
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final milestone = _nextMilestone;
    const milestones = [3, 7, 14, 30, 50, 100, 365];
    final milestoneStart = milestone == 3
        ? 0
        : milestones.lastWhere((value) => value < milestone, orElse: () => 0);
    final denominator = (milestone - milestoneStart).clamp(1, 9999);
    final progress = ((totalDays - milestoneStart) / denominator).clamp(
      0.0,
      1.0,
    );

    return Semantics(
      button: onTap != null,
      label: '$totalDays días de constancia. $_todayMessage',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF241C32),
                  Color(0xFF443052),
                  Color(0xFF65453E),
                ],
                stops: [0, .62, 1],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF35233F).withValues(alpha: .25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -35,
                  child: Container(
                    width: 125,
                    height: 125,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE6B76B).withValues(alpha: .16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FireAnimatedIcon(play: !reducedMotion && playAnimation),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TU CONSTANCIA',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFEBCB91),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.45,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$totalDays',
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 30,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        totalDays == 1
                                            ? 'día caminando'
                                            : 'días caminando',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withValues(
                                            alpha: .76,
                                          ),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                          color: Colors.white.withValues(alpha: .62),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          completedMoments >= totalMoments
                              ? Icons.verified_rounded
                              : Icons.timelapse_rounded,
                          color: const Color(0xFFEBCB91),
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _todayMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: .82),
                              fontSize: 10.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreakWeekRow(days: weekDays),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(
                                alpha: .10,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFE7B868),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${milestone - totalDays} para $milestone días',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: .66),
                            fontSize: 9.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
