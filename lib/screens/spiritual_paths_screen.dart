import 'package:flutter/material.dart';

import '../data/spiritual_paths_catalog.dart';
import '../features/paths/presentation/path_photos.dart';
import '../models/spiritual_path.dart';
import '../services/spiritual_path_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'spiritual_path_detail_screen.dart';
import 'package:verbum/design_system/design_system.dart';

class SpiritualPathsScreen extends StatefulWidget {
  const SpiritualPathsScreen({super.key});

  @override
  State<SpiritualPathsScreen> createState() => _SpiritualPathsScreenState();
}

class _SpiritualPathsScreenState extends State<SpiritualPathsScreen> {
  final _service = SpiritualPathService();
  late Future<_PathsState> _state;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _state = _load();
  }

  Future<_PathsState> _load() async {
    final activeId = await _service.activePathId();
    final entries = await Future.wait(
      SpiritualPathsCatalog.paths.map(
        (path) async => MapEntry(path.id, await _service.progressFor(path.id)),
      ),
    );
    return _PathsState(activeId: activeId, progress: Map.fromEntries(entries));
  }

  Future<void> _open(SpiritualPath path) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SpiritualPathDetailScreen(path: path)),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VerbumAmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(title: Text('Caminos', style: context.type.display)),
              Expanded(
                child: FutureBuilder<_PathsState>(
                  future: _state,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: VEmptyState(loading: true, title: 'Cargando…'),
                      );
                    }
                    final state = snapshot.data!;
                    final active = state.activeId == null
                        ? null
                        : SpiritualPathsCatalog.byId(state.activeId!);
                    final featured =
                        active ??
                        SpiritualPathsCatalog.recommend(
                          hour: DateTime.now().hour,
                        );
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        VerbumSpace.gutter,
                        4,
                        VerbumSpace.gutter,
                        MediaQuery.paddingOf(context).bottom + 28,
                      ),
                      children: [
                        VFeatureCard(
                          eyebrow: active == null
                              ? 'Recomendado para hoy'
                              : 'En curso',
                          title: featured.title,
                          body: featured.subtitle,
                          photo: photoForPath(featured.id),
                          footer: VButton(
                            label: active == null
                                ? 'Conocer el camino'
                                : 'Continuar',
                            icon: active == null
                                ? VerbumIcons.arrowRight
                                : VerbumIcons.play,
                            variant: VButtonVariant.inverse,
                            compact: true,
                            onPressed: () => _open(featured),
                          ),
                        ),
                        VSectionHeader(
                          active == null
                              ? 'Elige lo que hoy necesitas'
                              : 'Otros caminos para después',
                          eyebrow: active == null
                              ? 'Empieza por aquí'
                              : 'Explora',
                          padding: const EdgeInsets.fromLTRB(2, 26, 2, 12),
                        ),
                        for (final path in SpiritualPathsCatalog.paths)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PathCard(
                              path: path,
                              progress:
                                  state.progress[path.id] ??
                                  SpiritualPathProgress(pathId: path.id),
                              active: path.id == state.activeId,
                              onTap: () => _open(path),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathsState {
  final String? activeId;
  final Map<String, SpiritualPathProgress> progress;
  const _PathsState({required this.activeId, required this.progress});
}

class _PathCard extends StatelessWidget {
  final SpiritualPath path;
  final SpiritualPathProgress progress;
  final bool active;
  final VoidCallback onTap;
  const _PathCard({
    required this.path,
    required this.progress,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final value = progress.progressFor(path.days.length);
    final complete = progress.isComplete(path.days.length);
    return VSurfaceCard(
      onTap: onTap,
      borderColor: active ? p.rubric : null,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          VPhotoFrame(photoForPath(path.id), width: 58, aspectRatio: 1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(path.title, style: type.heading)),
                    if (complete)
                      VIcon(
                        VerbumIcons.sealCheck,
                        weight: VIconWeight.fill,
                        size: 18,
                        color: p.accent,
                      )
                    else if (active)
                      const VMetaChip(label: 'En curso'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${path.days.length} días · ${path.minutesPerDay} min al día',
                  style: type.caption,
                ),
                if (value > 0) ...[
                  const SizedBox(height: 10),
                  VProgressBar(
                    value: value,
                    semanticLabel: 'Avance del camino',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          VIcon(VerbumIcons.caretRight, size: 18, color: p.inkSubtle),
        ],
      ),
    );
  }
}
