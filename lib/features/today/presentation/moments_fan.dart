import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../application/day_moments.dart';
import '../application/today_schedule.dart';
import 'mission_visuals.dart';

/// Los momentos del día como un abanico de tarjetas que se desliza.
///
/// Abre centrado en el siguiente momento pendiente; las vecinas asoman
/// giradas, como cartas en la mano.
class MomentsFan extends StatefulWidget {
  const MomentsFan({
    super.key,
    required this.moments,
    required this.nightAvailable,
    required this.onOpen,
    this.verseText,
    this.verseReference,
  });

  final List<DayMoment> moments;
  final bool nightAvailable;
  final ValueChanged<DayMoment> onOpen;
  final String? verseText;
  final String? verseReference;

  @override
  State<MomentsFan> createState() => _MomentsFanState();
}

class _MomentsFanState extends State<MomentsFan> {
  // Las misiones se mutan en sitio, así que se recuerda el último índice.
  late int _next = initialMomentIndex(widget.moments);
  late final PageController _controller = PageController(
    viewportFraction: 0.8,
    initialPage: _next,
  );

  /// Si el progreso llega después (Firestore), se recentra en el nuevo
  /// siguiente momento.
  @override
  void didUpdateWidget(MomentsFan old) {
    super.didUpdateWidget(old);
    final next = initialMomentIndex(widget.moments);
    if (next != _next && _controller.hasClients) {
      _next = next;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = initialMomentIndex(widget.moments);
    // El alto crece con el texto ampliado para no recortar contenido.
    final height = MediaQuery.textScalerOf(
      context,
    ).scale(318).clamp(318.0, 520.0);

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: _controller,
        clipBehavior: Clip.none,
        itemCount: widget.moments.length,
        itemBuilder: (context, i) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final page =
                _controller.hasClients &&
                    _controller.position.hasContentDimensions
                ? _controller.page!
                : next.toDouble();
            final d = (i - page).clamp(-1.5, 1.5);
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..translateByDouble(0, d.abs() * 14, 0, 1)
                ..rotateZ(d * 0.07)
                ..scaleByDouble(1 - d.abs() * 0.08, 1 - d.abs() * 0.08, 1, 1),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 18),
            child: _MomentCard(
              moment: widget.moments[i],
              isNext: i == next && !widget.moments[i].done,
              locked: _locked(widget.moments[i]),
              verseText: widget.verseText,
              verseReference: widget.verseReference,
              onOpen: () => widget.onOpen(widget.moments[i]),
            ),
          ),
        ),
      ),
    );
  }

  bool _locked(DayMoment m) =>
      m.mission.id == 'night' && !widget.nightAvailable && !m.done;
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.isNext,
    required this.locked,
    required this.onOpen,
    this.verseText,
    this.verseReference,
  });

  final DayMoment moment;
  final bool isNext;
  final bool locked;
  final VoidCallback onOpen;
  final String? verseText;
  final String? verseReference;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final mission = moment.mission;
    final bg = isNext ? p.inverse : p.surface;
    final fg = isNext ? p.onInverse : p.ink;
    final muted = isNext ? p.onInverse.withValues(alpha: 0.78) : p.inkMuted;
    final verse =
        mission.id == 'verse' && (verseText?.trim().isNotEmpty ?? false);

    return Material(
      color: bg,
      elevation: isNext ? 10 : 4,
      shadowColor: p.ink.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(VerbumRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Pill(
                    label: moment.time,
                    bg: isNext
                        ? p.onInverse.withValues(alpha: 0.16)
                        : p.surfaceMuted,
                    fg: isNext ? p.onInverse : p.rubric,
                  ),
                  if (moment.done)
                    _Pill(
                      label: 'Hecho',
                      icon: VerbumIcons.check,
                      bg: p.accentSoft,
                      fg: p.rubric,
                    )
                  else if (isNext)
                    _Pill(label: 'Ahora', bg: p.butter, fg: p.onButter)
                  else if (locked)
                    VIcon(VerbumIcons.lockSimple, size: 18, color: p.inkSubtle),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isNext ? p.butter : p.accentSoft,
                  borderRadius: BorderRadius.circular(VerbumRadius.tile),
                ),
                child: VIcon(
                  iconForMission(mission),
                  weight: VIconWeight.duotone,
                  size: 32,
                  color: isNext ? p.onButter : p.rubric,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                shortLabelForMission(mission),
                style: type.rubric.copyWith(
                  color: isNext ? p.butter : p.rubric,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mission.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: type.heading.copyWith(color: fg),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  verse
                      ? '«${verseText!.trim()}» ${verseReference ?? ''}'.trim()
                      : locked
                      ? 'Disponible desde las $nightPrayerStartHour:00'
                      : mission.description,
                  overflow: TextOverflow.fade,
                  style: (verse ? type.scripture : type.body).copyWith(
                    color: muted,
                    fontSize: verse ? 16 : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VIcon(VerbumIcons.clock, size: 16, color: muted),
                      const SizedBox(width: 4),
                      Text(
                        '${mission.durationMinutes} min',
                        style: type.caption.copyWith(color: muted),
                      ),
                    ],
                  ),
                  if (!locked)
                    VButton(
                      label: moment.done ? 'Volver' : 'Comenzar',
                      icon: VerbumIcons.arrowRight,
                      compact: true,
                      variant: isNext
                          ? VButtonVariant.inverse
                          : VButtonVariant.solid,
                      onPressed: onOpen,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final VerbumIcons? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            VIcon(icon!, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.type.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
