import 'package:flutter/material.dart';

import '../data/spiritual_paths_catalog.dart';
import '../models/spiritual_path.dart';
import '../screens/spiritual_path_detail_screen.dart';
import '../screens/spiritual_paths_screen.dart';
import '../services/spiritual_path_service.dart';
import '../services/personalization_service.dart';
import '../services/storage_service.dart';
import '../design_system/design_system.dart';

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
          title: path.title,
          isActive: state.isActive,
          detail: state.isActive
              ? 'Día $next · ${path.days[next - 1].title}'
              : '${path.subtitle} · Ritmo de ${state.preferredMinutes} min',
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

/// Vista del camino espiritual en "Hoy". Solo presentación.
class SpiritualPathTodayView extends StatelessWidget {
  const SpiritualPathTodayView({
    super.key,
    required this.title,
    required this.detail,
    required this.isActive,
    required this.onContinue,
    required this.onSeeAll,
    this.progress,
  });

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
    return VSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VIcon(
                VerbumIcons.compass,
                weight: VIconWeight.duotone,
                size: 30,
                color: p.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VRubricLabel(
                      isActive ? 'Tu camino activo' : 'Para este momento',
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: type.heading),
                  ],
                ),
              ),
              VButton(
                label: 'Ver todos',
                variant: VButtonVariant.text,
                compact: true,
                onPressed: onSeeAll,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(detail, style: type.body),
          if (progress != null) ...[
            const SizedBox(height: 10),
            VProgressBar(value: progress!, semanticLabel: 'Avance del camino'),
          ],
          const SizedBox(height: 14),
          VButton(
            label: isActive ? 'Continuar mi camino' : 'Explorar este camino',
            icon: VerbumIcons.arrowRight,
            variant: VButtonVariant.outlined,
            expanded: true,
            onPressed: onContinue,
          ),
        ],
      ),
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
