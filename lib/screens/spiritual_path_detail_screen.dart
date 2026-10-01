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

  void _reload() => _progress = _service.progressFor(widget.path.id);

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
              return Column(
                children: [
                  AppBar(
                    title: Text(
                      'Camino espiritual',
                      style: context.type.heading,
                    ),
                    actions: [
                      VIconButton(
                        icon: VerbumIcons.shareNetwork,
                        semanticLabel: 'Invitar a alguien',
                        variant: VIconButtonVariant.ghost,
                        onPressed: _share,
                      ),
                      const SizedBox(width: 8),
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
                        _PathHero(path: path, progress: progress),
                        VSectionHeader(
                          '${path.days.length} pasos, a tu propio ritmo',
                          eyebrow: 'Lo que vas a recorrer',
                          padding: const EdgeInsets.fromLTRB(2, 26, 2, 12),
                        ),
                        VDashedPath(
                          gap: 16,
                          children: [
                            for (final day in path.days)
                              VStepRow(
                                number: day.number,
                                title: day.title,
                                subtitle: day.subtitle,
                                state:
                                    progress.completedDays.contains(day.number)
                                    ? VStepState.done
                                    : day.number == next && !complete
                                    ? VStepState.current
                                    : VStepState.upcoming,
                                locked:
                                    !(day.number <= next ||
                                        progress.completedDays.contains(
                                          day.number,
                                        ) ||
                                        complete),
                                onTap: () => _openDay(day.number),
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

class _PathHero extends StatelessWidget {
  final SpiritualPath path;
  final SpiritualPathProgress progress;
  const _PathHero({required this.path, required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = progress.progressFor(path.days.length);
    return VFeatureCard(
      eyebrow: path.category,
      title: path.title,
      body: path.description,
      photo: photoForPath(path.id),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              VMetaChip(
                icon: VerbumIcons.calendarBlank,
                label: '${path.days.length} días',
                color: p.butter,
              ),
              VMetaChip(
                icon: VerbumIcons.clock,
                label: '${path.minutesPerDay} min diarios',
                color: p.butter,
              ),
            ],
          ),
          if (value > 0) ...[
            const SizedBox(height: 16),
            VProgressBar(value: value, semanticLabel: 'Avance del camino'),
            const SizedBox(height: 6),
            Text(
              '${progress.completedDays.length} de ${path.days.length} días completados',
              style: context.type.caption.copyWith(
                color: p.onInverse.withValues(alpha: .7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
