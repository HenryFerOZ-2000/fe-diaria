import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../application/day_moments.dart';
import '../application/today_schedule.dart';
import 'mission_visuals.dart';

/// Los momentos del día como un abanico de cartas sobre fondo periwinkle.
///
/// Abre centrado en el siguiente momento pendiente; las vecinas asoman a
/// los lados, giradas y en lavanda. Debajo, puntos de página.
class MomentsFan extends StatefulWidget {
  const MomentsFan({
    super.key,
    required this.moments,
    required this.nightAvailable,
    required this.onOpen,
  });

  final List<DayMoment> moments;
  final bool nightAvailable;
  final ValueChanged<DayMoment> onOpen;

  @override
  State<MomentsFan> createState() => _MomentsFanState();
}

class _MomentsFanState extends State<MomentsFan> {
  // Las misiones se mutan en sitio, así que se recuerda el último índice.
  late int _next = initialMomentIndex(widget.moments);
  late final PageController _controller = PageController(
    viewportFraction: 0.58,
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

  double get _page =>
      _controller.hasClients && _controller.position.hasContentDimensions
      ? _controller.page!
      : _next.toDouble();

  @override
  Widget build(BuildContext context) {
    // El alto crece con el texto ampliado para no recortar contenido.
    final height = MediaQuery.textScalerOf(
      context,
    ).scale(330).clamp(330.0, 520.0);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            clipBehavior: Clip.none,
            itemCount: widget.moments.length,
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final d = (i - _page).clamp(-1.5, 1.5);
                final focus = (1 - d.abs()).clamp(0.0, 1.0);
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..translateByDouble(0, d.abs() * 26, 0, 1)
                    ..rotateZ(d * 0.16)
                    ..scaleByDouble(1 - d.abs() * 0.1, 1 - d.abs() * 0.1, 1, 1),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 30),
                    child: _MomentCard(
                      moment: widget.moments[i],
                      focus: focus,
                      locked: _locked(widget.moments[i]),
                      onOpen: () => widget.onOpen(widget.moments[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                _Dots(count: widget.moments.length, page: _page),
          ),
        ),
      ],
    );
  }

  bool _locked(DayMoment m) =>
      m.mission.id == 'night' && !widget.nightAvailable && !m.done;
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.focus,
    required this.locked,
    required this.onOpen,
  });

  final DayMoment moment;

  /// 1 = carta al centro (blanca), 0 = carta lateral (lavanda).
  final double focus;
  final bool locked;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final mission = moment.mission;
    final side = Color.alphaBlend(
      p.onInverse.withValues(alpha: 0.62),
      p.inverse,
    );
    final caption = locked
        ? 'Desde las $nightPrayerStartHour:00'
        : moment.done
        ? '${shortLabelForMission(mission)} · Hecho'
        : '${shortLabelForMission(mission)} · ${mission.durationMinutes} min';

    return Semantics(
      button: !locked,
      label: '${moment.time}, ${mission.title}, $caption',
      excludeSemantics: true,
      child: Material(
        color: Color.lerp(side, p.surface, focus),
        elevation: 4 + focus * 10,
        shadowColor: p.ink.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(VerbumRadius.sheet),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: locked ? null : onOpen,
          child: Stack(
            children: [
              if (moment.done)
                Positioned(
                  top: 14,
                  left: 14,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: p.sage,
                    child: VIcon(VerbumIcons.check, size: 14, color: p.surface),
                  ),
                ),
              if (locked)
                Positioned(
                  top: 16,
                  right: 16,
                  child: VIcon(
                    VerbumIcons.lockSimple,
                    size: 18,
                    color: p.inkSubtle,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                child: Column(
                  children: [
                    Text(
                      moment.time,
                      style: type.title.copyWith(color: p.rubric, fontSize: 26),
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          child: VIcon(
                            iconForMission(mission),
                            size: 92,
                            color: p.rubric,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      mission.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.heading.copyWith(color: p.rubric),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: type.caption.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page});

  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Builder(
            builder: (context) {
              final t = (1 - (i - page).abs()).clamp(0.0, 1.0);
              return Container(
                width: 7 + 17 * t,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: p.onInverse.withValues(alpha: 0.4 + 0.6 * t),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            },
          ),
      ],
    );
  }
}
