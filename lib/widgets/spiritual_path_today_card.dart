import 'package:flutter/material.dart';

import '../data/spiritual_paths_catalog.dart';
import '../models/spiritual_path.dart';
import '../screens/spiritual_path_detail_screen.dart';
import '../screens/spiritual_paths_screen.dart';
import '../services/spiritual_path_service.dart';
import '../services/personalization_service.dart';
import '../services/storage_service.dart';
import '../design_system/design_system.dart';
import '../features/paths/presentation/path_photos.dart';

class SpiritualPathTodayCard extends StatefulWidget {
  const SpiritualPathTodayCard({super.key});

  @override
  State<SpiritualPathTodayCard> createState() => _SpiritualPathTodayCardState();
}

class _SpiritualPathTodayCardState extends State<SpiritualPathTodayCard> {
  final _service = SpiritualPathService();
  late Future<_TodayPathState> _state;

  @override
  void initState() {
    super.initState();
    _state = _load();
  }

  Future<_TodayPathState> _load() async {
    final activeId = await _service.activePathId();
    final storage = StorageService();
    final preference = storage.getPreferredSpiritualMoment();
    final recommendationHour = preference == 'evening'
        ? 21
        : preference == 'morning'
        ? 9
        : DateTime.now().hour;
    final path = activeId == null
        ? SpiritualPathsCatalog.recommend(
            hour: recommendationHour,
            emotion: PersonalizationService().getUserEmotion(),
          )
        : SpiritualPathsCatalog.byId(activeId);
    final progress = await _service.progressFor(path.id);
    return _TodayPathState(
      path: path,
      progress: progress,
      isActive: activeId != null,
      preferredMinutes: storage.getPreferredDailyMinutes(),
    );
  }

  Future<void> _open(_TodayPathState state) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpiritualPathDetailScreen(path: state.path),
      ),
    );
    if (mounted) setState(() => _state = _load());
  }

  Future<void> _openCatalog() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SpiritualPathsScreen()));
    if (mounted) setState(() => _state = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayPathState>(
      future: _state,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final state = snapshot.data!;
        final path = state.path;
        final next = state.progress.nextDay(path.days.length);
        return SpiritualPathTodayView(
          pathId: path.id,
          title: path.title,
          isActive: state.isActive,
          detail: state.isActive
              ? 'Camino · día $next de ${path.days.length}'
              : 'Para este momento · ${state.preferredMinutes} min',
          progress: state.isActive
              ? state.progress.progressFor(path.days.length)
              : null,
          onContinue: () => _open(state),
          onSeeAll: _openCatalog,
        );
      },
    );
  }
}

/// Vista del camino espiritual en "Hoy": foto enmarcada, avance en
/// salvia y, en la cabecera, el acceso a todos los caminos.
/// Solo presentación.
class SpiritualPathTodayView extends StatelessWidget {
  const SpiritualPathTodayView({
    super.key,
    required this.pathId,
    required this.title,
    required this.detail,
    required this.isActive,
    required this.onContinue,
    required this.onSeeAll,
    this.progress,
  });

  final String pathId;
  final String title;
  final String detail;
  final bool isActive;

  /// Avance del camino activo (0–1); `null` si aún no se ha empezado.
  final double? progress;
  final VoidCallback onContinue;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VSectionHeader(
          'Continúa',
          trailing: 'Ver caminos',
          onTrailingTap: onSeeAll,
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
        ),
        VSurfaceCard(
          onTap: onContinue,
          radius: VerbumRadius.card,
          padding: const EdgeInsets.all(12),
          semanticLabel: '$title. $detail',
          child: Row(
            children: [
              VPhotoFrame(photoForPath(pathId), width: 62, aspectRatio: 1),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail,
                      style: type.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.heading.copyWith(fontSize: 16),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: p.sage,
                          backgroundColor: p.surfaceMuted,
                          semanticsLabel: 'Avance del camino',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VIcon(VerbumIcons.caretRight, size: 18, color: p.inkSubtle),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayPathState {
  final SpiritualPath path;
  final SpiritualPathProgress progress;
  final bool isActive;
  final int preferredMinutes;
  const _TodayPathState({
    required this.path,
    required this.progress,
    required this.isActive,
    required this.preferredMinutes,
  });
}
