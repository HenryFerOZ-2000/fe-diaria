import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import 'v_icon.dart';
import 'v_icon_button.dart';

/// Calendario de un mes con días marcados (constancia, días de un camino…).
/// No guarda estado: el mes visible y la navegación vienen de fuera.
class VMonthCalendar extends StatelessWidget {
  const VMonthCalendar({
    super.key,
    required this.month,
    required this.title,
    required this.isMarked,
    required this.today,
    this.onPrevious,
    this.onNext,
    this.dayLabel,
    this.weekdayLabels = const ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
  });

  /// Cualquier fecha del mes a mostrar.
  final DateTime month;
  final String title;
  final bool Function(DateTime day) isMarked;
  final DateTime today;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Etiqueta accesible por día ("3 de septiembre, completado").
  final String Function(DateTime day, bool marked)? dayLabel;
  final List<String> weekdayLabels;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = ((offset + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: [
        Row(
          children: [
            VIconButton(
              icon: VerbumIcons.caretLeft,
              semanticLabel: 'Mes anterior',
              variant: VIconButtonVariant.ghost,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: type.heading.copyWith(fontSize: 19),
              ),
            ),
            VIconButton(
              icon: VerbumIcons.caretRight,
              semanticLabel: 'Mes siguiente',
              variant: VIconButtonVariant.ghost,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: type.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - offset + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(month.year, month.month, dayNumber);
            final marked = isMarked(day);
            final isToday = _sameDay(day, today);
            return Semantics(
              label: dayLabel?.call(day, marked) ?? '$dayNumber',
              excludeSemantics: true,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marked ? p.sage : Colors.transparent,
                  border: Border.all(
                    color: marked
                        ? p.sage
                        : isToday
                        ? p.rubric
                        : p.lineSoft,
                    width: isToday && !marked ? 1.5 : 1,
                  ),
                ),
                child: marked
                    ? VIcon(VerbumIcons.check, size: 15, color: p.surface)
                    : Text(
                        '$dayNumber',
                        style: type.caption.copyWith(
                          color: isToday ? p.rubric : p.inkMuted,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
