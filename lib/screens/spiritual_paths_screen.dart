import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/spiritual_paths_catalog.dart';
import '../models/spiritual_path.dart';
import '../services/spiritual_path_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'spiritual_path_detail_screen.dart';

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
      SpiritualPathsCatalog.paths.map((path) async =>
          MapEntry(path.id, await _service.progressFor(path.id))),
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
              AppBar(
                title: Text(
                  'Caminos',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<_PathsState>(
                  future: _state,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final state = snapshot.data!;
                    final active = state.activeId == null
                        ? null
                        : SpiritualPathsCatalog.byId(state.activeId!);
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        MediaQuery.paddingOf(context).bottom + 28,
                      ),
                      children: [
                        _PathsHero(activePath: active, onOpen: _open),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          eyebrow: active == null ? 'EMPIEZA POR AQUÍ' : 'EXPLORA',
                          title: active == null
                              ? 'Elige lo que hoy necesitas'
                              : 'Otros caminos para después',
                        ),
                        const SizedBox(height: 13),
                        ...SpiritualPathsCatalog.paths.map((path) {
                          final progress = state.progress[path.id] ??
                              SpiritualPathProgress(pathId: path.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 13),
                            child: _PathCard(
                              path: path,
                              progress: progress,
                              active: path.id == state.activeId,
                              onTap: () => _open(path),
                            ),
                          );
                        }),
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

class _PathsHero extends StatelessWidget {
  final SpiritualPath? activePath;
  final ValueChanged<SpiritualPath> onOpen;
  const _PathsHero({required this.activePath, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final recommended = activePath ??
        SpiritualPathsCatalog.recommend(hour: DateTime.now().hour);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2345), Color(0xFF493878), Color(0xFF625079)],
        ),
        borderRadius: BorderRadius.circular(29),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33264F).withValues(alpha: .25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.route_rounded, color: Color(0xFFF0D9A1)),
              ),
              const Spacer(),
              Text(
                activePath == null ? 'RECOMENDADO PARA HOY' : 'EN CURSO',
                style: GoogleFonts.inter(
                  color: const Color(0xFFF0D9A1),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            activePath == null ? 'Un camino para este momento' : 'Continúa tu camino',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: .66),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommended.title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            recommended.subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: .75),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => onOpen(recommended),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF34284F),
            ),
            icon: Icon(activePath == null ? Icons.arrow_forward_rounded : Icons.play_arrow_rounded),
            label: Text(activePath == null ? 'Conocer el camino' : 'Continuar'),
          ),
        ],
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final SpiritualPath path;
  final SpiritualPathProgress progress;
  final bool active;
  final VoidCallback onTap;
  const _PathCard({required this.path, required this.progress, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = progress.progressFor(path.days.length);
    final complete = progress.isComplete(path.days.length);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active
                  ? path.accent.withValues(alpha: .55)
                  : scheme.outlineVariant,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: path.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(path.icon, color: path.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            path.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (active || complete)
                          Icon(
                            complete ? Icons.check_circle_rounded : Icons.bolt_rounded,
                            size: 17,
                            color: complete ? scheme.tertiary : path.accent,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${path.days.length} días · ${path.minutesPerDay} min al día',
                      style: GoogleFonts.inter(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                    if (value > 0) ...[
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          color: path.accent,
                          backgroundColor: path.accent.withValues(alpha: .12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  const _SectionHeader({required this.eyebrow, required this.title});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      );
}
