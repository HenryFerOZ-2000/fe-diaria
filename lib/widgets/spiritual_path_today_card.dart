import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/spiritual_paths_catalog.dart';
import '../models/spiritual_path.dart';
import '../screens/spiritual_path_detail_screen.dart';
import '../screens/spiritual_paths_screen.dart';
import '../services/spiritual_path_service.dart';
import '../services/personalization_service.dart';
import '../services/storage_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayPathState>(
      future: _state,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final state = snapshot.data!;
        final path = state.path;
        final next = state.progress.nextDay(path.days.length);
        final scheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  path.accent.withValues(alpha: .11),
                  scheme.surface,
                ),
                scheme.surface.withValues(alpha: .92),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: path.accent.withValues(alpha: .25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration: BoxDecoration(
                      color: path.accent.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(path.icon, size: 21, color: path.accent),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.isActive
                              ? 'TU CAMINO ACTIVO'
                              : 'PARA ESTE MOMENTO',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            letterSpacing: 1.25,
                            fontWeight: FontWeight.w800,
                            color: path.accent,
                          ),
                        ),
                        Text(
                          path.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SpiritualPathsScreen(),
                        ),
                      );
                      if (mounted) setState(() => _state = _load());
                    },
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                state.isActive
                    ? 'Día $next · ${path.days[next - 1].title}'
                    : '${path.subtitle} · Ritmo de ${state.preferredMinutes} min',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (state.isActive) ...[
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: state.progress.progressFor(path.days.length),
                    minHeight: 4,
                    color: path.accent,
                    backgroundColor: path.accent.withValues(alpha: .12),
                  ),
                ),
              ],
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _open(state),
                  style: FilledButton.styleFrom(
                    backgroundColor: path.accent,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    state.isActive
                        ? Icons.play_arrow_rounded
                        : Icons.route_rounded,
                  ),
                  label: Text(
                    state.isActive
                        ? 'Continuar mi camino'
                        : 'Explorar este camino',
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
