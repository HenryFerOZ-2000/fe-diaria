import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/spiritual_stats.dart';
import '../services/spiritual_stats_service.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/today/application/constancy_calendar.dart';
import '../features/today/application/constancy_progress.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final _statsService = SpiritualStatsService();
  StreamSubscription<SpiritualStats>? _subscription;
  bool _loading = true;
  int _current = 0;
  int _best = 0;
  String? _last;
  Map<String, bool> _activeDays = {};
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _load();
    if (FirebaseAuth.instance.currentUser != null) {
      _subscription = _statsService.statsStream().listen(
        _applyStats,
        onError: (Object error) {
          debugPrint('[StreakScreen] stream error: $error');
          if (mounted) setState(() => _loading = false);
        },
      );
    }
  }

  Future<void> _load() async {
    if (FirebaseAuth.instance.currentUser == null) {
      final local = await StreakService(StorageService()).resetIfNeeded();
      if (!mounted) return;
      final active = <String, bool>{};
      if (local.current > 0 && local.lastDateYmd != null) {
        active[local.lastDateYmd!] = true;
      }
      setState(() {
        _current = local.current;
        _best = local.best;
        _last = local.lastDateYmd;
        _activeDays = active;
        _loading = false;
      });
      return;
    }
    _applyStats(await _statsService.getStats());
  }

  void _applyStats(SpiritualStats stats) {
    if (!mounted) return;
    setState(() {
      _current = stats.currentStreak;
      _best = stats.bestStreak;
      _last = stats.lastActiveDate;
      _activeDays = stats.activeDaysMap;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool get _todayComplete {
    final today = ymdKey(DateTime.now());
    return _activeDays[today] == true || _last == today;
  }

  int get _recordedDays {
    final mapped = _activeDays.values.where((value) => value).length;
    return mapped > _current ? mapped : _current;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final progress = ConstancyProgress.from(
      totalDays: _current,
      completedMoments: _todayComplete ? 1 : 0,
      totalMoments: 1,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VerbumAmbientBackground(
        glowAlignment: const Alignment(1.2, -.8),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: VEmptyState(loading: true, title: 'Cargando…'),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    VAppBar.sliver(
                      context,
                      title: Text('Mi constancia', style: context.type.heading),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        VerbumSpace.gutter,
                        8,
                        VerbumSpace.gutter,
                        32,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _hero(context),
                          const SizedBox(height: 12),
                          VActionTile(
                            tone: _todayComplete
                                ? VSurfaceTone.accent
                                : VSurfaceTone.paper,
                            icon: _todayComplete
                                ? VerbumIcons.sealCheck
                                : VerbumIcons.sun,
                            iconColor: _todayComplete
                                ? context.palette.accent
                                : context.palette.rubric,
                            title: _todayComplete
                                ? 'Hoy está a salvo'
                                : 'Tu camino de hoy',
                            subtitle: _todayComplete
                                ? 'Ya completaste tus tres momentos esenciales.'
                                : 'Completa tus tres momentos esenciales para cuidar tu constancia.',
                            trailingIcon: _todayComplete
                                ? null
                                : VerbumIcons.arrowRight,
                            onTap: _todayComplete
                                ? null
                                : () => Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
                                        '/home',
                                        (route) => false,
                                      ),
                          ),
                          const VSectionHeader(
                            'Cada día cuenta',
                            eyebrow: 'Tu recorrido',
                            padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
                          ),
                          VSurfaceCard(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                            child: VMonthCalendar(
                              month: _visibleMonth,
                              title: monthTitle(_visibleMonth),
                              today: now,
                              isMarked: (day) =>
                                  _activeDays[ymdKey(day)] == true,
                              dayLabel: (day, marked) =>
                                  '${day.day} de ${spanishMonths[day.month - 1]}${marked ? ', completado' : ''}',
                              onPrevious: () => setState(
                                () => _visibleMonth = DateTime(
                                  _visibleMonth.year,
                                  _visibleMonth.month - 1,
                                ),
                              ),
                              onNext:
                                  _visibleMonth.year == now.year &&
                                      _visibleMonth.month == now.month
                                  ? null
                                  : () => setState(
                                      () => _visibleMonth = DateTime(
                                        _visibleMonth.year,
                                        _visibleMonth.month + 1,
                                      ),
                                    ),
                            ),
                          ),
                          const VSectionHeader(
                            'Un paso a la vez',
                            eyebrow: 'Próximo hito',
                            padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
                          ),
                          _milestone(context, progress),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: VStatTile(
                                  value:
                                      '${activeDaysInMonth(_activeDays, now)}',
                                  label: 'días este mes',
                                  icon: VerbumIcons.calendarDots,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: VStatTile(
                                  value: '$_recordedDays',
                                  label: 'días registrados',
                                  icon: VerbumIcons.infinity,
                                  iconColor: context.palette.rubric,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          VSurfaceCard(
                            tone: VSurfaceTone.muted,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VIcon(
                                  VerbumIcons.flowerLotus,
                                  weight: VIconWeight.duotone,
                                  size: 26,
                                  color: context.palette.gold,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No se trata de no fallar',
                                        style: context.type.bodyStrong,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tu constancia crece cuando completas los tres momentos esenciales del día. Si interrumpes el recorrido, siempre puedes volver a comenzar.',
                                        style: context.type.body,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Widget _hero(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    Widget metric(VerbumIcons icon, String label, String value) => Expanded(
      child: Row(
        children: [
          VIcon(icon, size: 18, color: p.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.caption.copyWith(
                    color: p.onInverse.withValues(alpha: .6),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodyStrong.copyWith(color: p.onInverse),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return VSurfaceCard(
      tone: VSurfaceTone.ink,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: VRubricLabel('Tu camino hasta hoy', color: p.gold),
              ),
              VIcon(
                VerbumIcons.flame,
                weight: VIconWeight.fill,
                size: 26,
                color: p.gold,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$_current',
                  style: type.display.copyWith(
                    color: p.onInverse,
                    fontSize: 56,
                    height: .95,
                  ),
                ),
                TextSpan(
                  text: _current == 1 ? '  día caminando' : '  días caminando',
                  style: type.body.copyWith(
                    color: p.onInverse.withValues(alpha: .75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: p.onInverse.withValues(alpha: .12)),
          const SizedBox(height: 14),
          Row(
            children: [
              metric(
                VerbumIcons.medal,
                'Mejor recorrido',
                _best == 1 ? '1 día' : '$_best días',
              ),
              const SizedBox(width: 12),
              metric(
                VerbumIcons.clockCounterClockwise,
                'Actividad reciente',
                lastActiveLabel(_last, DateTime.now()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _milestone(BuildContext context, ConstancyProgress progress) {
    final type = context.type;
    final remaining = progress.remainingDays;
    return VSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VIcon(
                VerbumIcons.sparkle,
                weight: VIconWeight.duotone,
                size: 30,
                color: context.palette.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress.nextMilestone} días de constancia',
                      style: type.bodyStrong.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining == 1
                          ? 'Falta un día para este hito.'
                          : 'Faltan $remaining días para este hito.',
                      style: type.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '$_current/${progress.nextMilestone}',
                style: type.bodyStrong.copyWith(color: context.palette.rubric),
              ),
            ],
          ),
          const SizedBox(height: 14),
          VProgressBar(
            value: progress.progress,
            height: 6,
            semanticLabel: 'Avance hacia ${progress.nextMilestone} días',
          ),
        ],
      ),
    );
  }
}
