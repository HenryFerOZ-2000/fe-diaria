import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../models/spiritual_path.dart';
import '../services/spiritual_path_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'spiritual_path_day_screen.dart';

class SpiritualPathDetailScreen extends StatefulWidget {
  final SpiritualPath path;
  const SpiritualPathDetailScreen({super.key, required this.path});

  @override
  State<SpiritualPathDetailScreen> createState() => _SpiritualPathDetailScreenState();
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
    await _service.start(widget.path.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpiritualPathDayScreen(
          path: widget.path,
          dayNumber: number,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  void _share() {
    Share.share(
      'Quiero recorrer contigo “${widget.path.title}” en Verbum: '
      '${widget.path.subtitle}.\n\nAbrir en Verbum: '
      'verbum://camino/${widget.path.id}\n\nDescarga Verbum: '
      'https://play.google.com/store/apps/details?id=com.ozcorp.verbum',
      subject: 'Un camino para compartir',
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
                    title: const Text('Camino espiritual'),
                    actions: [
                      IconButton(
                        tooltip: 'Invitar a alguien',
                        onPressed: _share,
                        icon: const Icon(Icons.ios_share_rounded),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        6,
                        16,
                        MediaQuery.paddingOf(context).bottom + 105,
                      ),
                      children: [
                        _PathHero(path: path, progress: progress),
                        const SizedBox(height: 26),
                        Text(
                          'LO QUE VAS A RECORRER',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Siete pasos, a tu propio ritmo',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 13),
                        ...path.days.map((day) {
                          final done = progress.completedDays.contains(day.number);
                          final available = day.number <= next || done || complete;
                          return _DayTile(
                            day: day,
                            done: done,
                            current: day.number == next && !complete,
                            available: available,
                            accent: path.accent,
                            onTap: available ? () => _openDay(day.number) : null,
                          );
                        }),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.paddingOf(context).bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openDay(complete ? 1 : next),
                        icon: Icon(
                          complete
                              ? Icons.replay_rounded
                              : started
                                  ? Icons.play_arrow_rounded
                                  : Icons.route_rounded,
                        ),
                        label: Text(
                          complete
                              ? 'Recorrer de nuevo'
                              : started
                                  ? 'Continuar con el día $next'
                                  : 'Comenzar este camino',
                        ),
                      ),
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
    final value = progress.progressFor(path.days.length);
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF29213F), path.accent.withValues(alpha: .92)],
        ),
        borderRadius: BorderRadius.circular(29),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(path.icon, color: Colors.white),
          ),
          const SizedBox(height: 22),
          Text(
            path.category.toUpperCase(),
            style: GoogleFonts.inter(
              color: const Color(0xFFF0D9A1),
              fontSize: 9,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            path.title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            path.description,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('${path.days.length} días', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 17),
              const Icon(Icons.schedule_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('${path.minutesPerDay} min diarios', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          if (value > 0) ...[
            const SizedBox(height: 19),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                color: const Color(0xFFF0D9A1),
                backgroundColor: Colors.white.withValues(alpha: .15),
              ),
            ),
            const SizedBox(height: 7),
            Text('${progress.completedDays.length} de ${path.days.length} días completados', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10.5)),
          ],
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final SpiritualPathDay day;
  final bool done;
  final bool current;
  final bool available;
  final Color accent;
  final VoidCallback? onTap;
  const _DayTile({required this.day, required this.done, required this.current, required this.available, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: available ? .92 : .55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: current ? accent.withValues(alpha: .55) : scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? accent : accent.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 19)
                      : Text('${day.number}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: available ? accent : scheme.outline)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: available ? scheme.onSurface : scheme.onSurfaceVariant)),
                      Text(day.subtitle, style: GoogleFonts.inter(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(available ? Icons.chevron_right_rounded : Icons.lock_outline_rounded, size: 19, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
