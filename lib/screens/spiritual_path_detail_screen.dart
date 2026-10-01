import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../features/paths/presentation/path_photos.dart';
import '../models/spiritual_path.dart';
import '../services/spiritual_path_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'spiritual_path_day_screen.dart';
import 'package:verbum/design_system/design_system.dart';

class SpiritualPathDetailScreen extends StatefulWidget {
  final SpiritualPath path;
  const SpiritualPathDetailScreen({super.key, required this.path});

  @override
  State<SpiritualPathDetailScreen> createState() =>
      _SpiritualPathDetailScreenState();
}

class _SpiritualPathDetailScreenState extends State<SpiritualPathDetailScreen> {
  final _service = SpiritualPathService();
  late Future<SpiritualPathProgress> _progress;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _progress = _service.progressFor(widget.path.id);
  }

  Future<void> _openDay(int number) async {
    await _service.start(widget.path.id, pathTitle: widget.path.title);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SpiritualPathDayScreen(path: widget.path, dayNumber: number),
      ),
    );
    if (mounted) setState(_reload);
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Quiero recorrer contigo “${widget.path.title}” en Verbum: '
            '${widget.path.subtitle}.\n\nAbrir en Verbum: '
            'verbum://camino/${widget.path.id}\n\nDescarga Verbum: '
            'https://play.google.com/store/apps/details?id=com.ozcorp.verbum',
        subject: 'Un camino para compartir',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    return Scaffold(
      body: VerbumAmbientBackground(
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<SpiritualPathProgress>(
            future: _progress,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final progress = snapshot.data!;
              final next = progress.nextDay(path.days.length);
              final started = progress.startedAt != null;
              final complete = progress.isComplete(path.days.length);
              final p = context.palette;
              String status(int day) {
                if (progress.completedDays.contains(day)) return 'hecho';
                if (day == next && !complete) return 'hoy';
                if (day == next + 1 && !complete) return 'mañana';
                return 'pronto';
              }

              Widget badge(String s) => switch (s) {
                'hecho' => _Badge(
                  label: 'Hecho',
                  icon: VerbumIcons.check,
                  bg: p.surfaceMuted,
                  fg: p.rubric,
                ),
                'hoy' => _Badge(
                  label: 'Hoy',
                  icon: VerbumIcons.play,
                  bg: p.butter,
                  fg: p.onButter,
                ),
                _ => Text(
                  s == 'mañana' ? 'Mañana' : 'Pronto',
                  style: context.type.caption,
                ),
              };

              return Column(
                children: [
                  AppBar(
                    actions: [
                      _Badge(
                        label:
                            '${path.days.length} días · ${path.minutesPerDay} min',
                        icon: VerbumIcons.calendarBlank,
                        bg: p.surfaceMuted,
                        fg: p.rubric,
                        large: true,
                      ),
                      const SizedBox(width: 8),
                      VIconButton(
                        icon: VerbumIcons.shareNetwork,
                        semanticLabel: 'Invitar a alguien',
                        onPressed: _share,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        VerbumSpace.gutter,
                        4,
                        VerbumSpace.gutter,
                        24,
                      ),
                      children: [
                        VTwoToneTitle(
                          path.title,
                          'Camino ·',
                          accentFirst: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          path.description,
                          style: context.type.body.copyWith(color: p.inkMuted),
                        ),
                        if (progress.completedDays.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          VProgressBar(
                            value: progress.progressFor(path.days.length),
                            semanticLabel: 'Avance del camino',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${progress.completedDays.length} de ${path.days.length} días completados',
                            style: context.type.caption,
                          ),
                        ],
                        const SizedBox(height: 22),
                        VWindingPath(
                          steps: [
                            for (final day in path.days)
                              VWindingStep(
                                photo: photoForPathDay(day.number),
                                title: 'Día ${day.number} · ${day.title}',
                                semanticLabel:
                                    'Día ${day.number}, ${day.title}, ${status(day.number)}',
                                badge: badge(status(day.number)),
                                onTap:
                                    day.number <= next ||
                                        progress.completedDays.contains(
                                          day.number,
                                        ) ||
                                        complete
                                    ? () => _openDay(day.number)
                                    : null,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VBottomBar(
                    child: VButton(
                      label: complete
                          ? 'Recorrer de nuevo'
                          : started
                          ? 'Continuar con el día $next'
                          : 'Comenzar este camino',
                      icon: complete
                          ? VerbumIcons.arrowCounterClockwise
                          : started
                          ? VerbumIcons.play
                          : VerbumIcons.arrowRight,
                      expanded: true,
                      onPressed: () => _openDay(complete ? 1 : next),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    this.large = false,
  });

  final String label;
  final VerbumIcons icon;
  final Color bg;
  final Color fg;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 10 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(large ? 16 : 99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VIcon(icon, size: large ? 16 : 12, color: fg),
          const SizedBox(width: 6),
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
