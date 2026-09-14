import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/spiritual_stats.dart';
import '../services/spiritual_stats_service.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
import '../widgets/verbum_ambient_background.dart';

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

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

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

  String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool get _todayComplete {
    final today = _ymd(DateTime.now());
    return _activeDays[today] == true || _last == today;
  }

  int get _nextMilestone {
    for (final value in const [3, 7, 14, 30, 50, 100, 365]) {
      if (_current < value) return value;
    }
    return ((_current ~/ 365) + 1) * 365;
  }

  int get _activeThisMonth => _activeDays.entries.where((entry) {
    if (entry.value != true) return false;
    final date = DateTime.tryParse(entry.key);
    return date != null &&
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month;
  }).length;

  int get _recordedDays {
    final mapped = _activeDays.values.where((value) => value).length;
    return mapped > _current ? mapped : _current;
  }

  String get _lastActiveLabel {
    final date = _last == null ? null : DateTime.tryParse(_last!);
    if (date == null) return 'Aún no hay un día completado';
    final now = DateTime.now();
    if (_ymd(date) == _ymd(now)) return 'Hoy';
    if (_ymd(date) == _ymd(now.subtract(const Duration(days: 1)))) {
      return 'Ayer';
    }
    return '${date.day} de ${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VerbumAmbientBackground(
        glowAlignment: const Alignment(1.2, -.8),
        child: SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: scheme.primary))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: .92),
                      surfaceTintColor: Colors.transparent,
                      title: Text(
                        'Mi constancia',
                        style: GoogleFonts.playfairDisplay(
                          color: scheme.onSurface,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      sliver: SliverList.list(
                        children: [
                          _buildHero(context),
                          const SizedBox(height: 14),
                          _buildTodayCard(context),
                          const SizedBox(height: 26),
                          _sectionHeading(
                            context,
                            eyebrow: 'TU RECORRIDO',
                            title: 'Cada día cuenta',
                          ),
                          const SizedBox(height: 12),
                          _buildCalendar(context),
                          const SizedBox(height: 26),
                          _sectionHeading(
                            context,
                            eyebrow: 'PRÓXIMO HITO',
                            title: 'Un paso a la vez',
                          ),
                          const SizedBox(height: 12),
                          _buildMilestone(context),
                          const SizedBox(height: 14),
                          _buildSummary(context),
                          const SizedBox(height: 14),
                          _buildMeaningCard(context),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF251D33), Color(0xFF493452), Color(0xFF6A493E)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D2948).withValues(alpha: .24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -20,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 126,
              color: Colors.white.withValues(alpha: .045),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TU CAMINO HASTA HOY',
                style: GoogleFonts.inter(
                  color: const Color(0xFFEBCB91),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.55,
                ),
              ),
              const SizedBox(height: 9),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$_current',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 50,
                        height: .95,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: _current == 1
                          ? '  día caminando'
                          : '  días caminando',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: .76),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _heroMetric(
                    Icons.workspace_premium_outlined,
                    'Mejor recorrido',
                    '$_best días',
                  ),
                  const SizedBox(width: 10),
                  _heroMetric(
                    Icons.history_rounded,
                    'Actividad reciente',
                    _lastActiveLabel,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .075),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFEBCB91), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _surface(
      context,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (_todayComplete ? const Color(0xFF5F8178) : scheme.primary)
                  .withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _todayComplete ? Icons.verified_rounded : Icons.wb_sunny_outlined,
              color: _todayComplete ? const Color(0xFF5F8178) : scheme.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayComplete ? 'Hoy está a salvo' : 'Tu camino de hoy',
                  style: GoogleFonts.inter(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _todayComplete
                      ? 'Ya completaste tus tres momentos esenciales.'
                      : 'Completa tus tres momentos esenciales para cuidar tu constancia.',
                  style: GoogleFonts.inter(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!_todayComplete)
            IconButton.filledTonal(
              tooltip: 'Ir a Hoy',
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false),
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeading(
    BuildContext context, {
    required String eyebrow,
    required String title,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: GoogleFonts.inter(
            color: scheme.secondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.45,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: scheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isCurrentMonth =
        _visibleMonth.year == now.year && _visibleMonth.month == now.month;
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final offset = first.weekday - 1;
    final cellCount = ((offset + daysInMonth + 6) ~/ 7) * 7;

    return _surface(
      context,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month - 1,
                  );
                }),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '${_months[_visibleMonth.month - 1][0].toUpperCase()}${_months[_visibleMonth.month - 1].substring(1)} ${_visibleMonth.year}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: isCurrentMonth
                    ? null
                    : () => setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month + 1,
                        );
                      }),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - offset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(
                _visibleMonth.year,
                _visibleMonth.month,
                dayNumber,
              );
              final done = _activeDays[_ymd(date)] == true;
              final today = _ymd(date) == _ymd(now);
              return Semantics(
                label:
                    '$dayNumber de ${_months[date.month - 1]}${done ? ', completado' : ''}',
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? const Color(0xFFE1B467)
                        : today
                        ? scheme.primary.withValues(alpha: .10)
                        : Colors.transparent,
                    border: Border.all(
                      color: done
                          ? const Color(0xFFE1B467)
                          : today
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: .12),
                    ),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2A2030),
                          size: 17,
                        )
                      : Text(
                          '$dayNumber',
                          style: GoogleFonts.inter(
                            color: today
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: today
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFFE1B467), 'Completado', scheme),
              const SizedBox(width: 16),
              _legendDot(scheme.primary, 'Hoy', scheme, outlined: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(
    Color color,
    String label,
    ColorScheme scheme, {
    bool outlined = false,
  }) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outlined ? Colors.transparent : color,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: scheme.onSurfaceVariant,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestone(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final target = _nextMilestone;
    final remaining = target - _current;
    final previous = const [
      0,
      3,
      7,
      14,
      30,
      50,
      100,
      365,
    ].lastWhere((value) => value < target);
    final progress = ((_current - previous) / (target - previous)).clamp(
      0.0,
      1.0,
    );
    return _surface(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1B467).withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFB27A34),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$target días de constancia',
                      style: GoogleFonts.inter(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      remaining == 1
                          ? 'Falta un día para este hito.'
                          : 'Faltan $remaining días para este hito.',
                      style: GoogleFonts.inter(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_current/$target',
                style: GoogleFonts.inter(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: const Color(0xFFD5A451),
              backgroundColor: scheme.primary.withValues(alpha: .08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            context,
            icon: Icons.calendar_month_outlined,
            value: '$_activeThisMonth',
            label: 'días este mes',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryTile(
            context,
            icon: Icons.all_inclusive_rounded,
            value: '$_recordedDays',
            label: 'días registrados',
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return _surface(
      context,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 21),
          const SizedBox(height: 11),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              color: scheme.onSurface,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: scheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.primary.withValues(alpha: .12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.spa_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se trata de no fallar',
                  style: GoogleFonts.inter(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tu constancia crece cuando completas los tres momentos esenciales del día. Si interrumpes el recorrido, siempre puedes volver a comenzar.',
                  style: GoogleFonts.inter(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _surface(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(17),
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF282330) : const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: scheme.outline.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .12 : .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
