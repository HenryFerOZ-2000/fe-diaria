import 'package:flutter/material.dart';

import '../domain/calendar_selection.dart';
import '../domain/liturgical_day.dart';
import 'liturgical_palette.dart';
import 'liturgy_source_sheet.dart';

class LiturgyDayScreen extends StatelessWidget {
  const LiturgyDayScreen({
    super.key,
    required this.day,
    required this.selection,
  });

  final LiturgicalDay day;
  final CalendarSelection selection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = day.primary.colors.firstOrNull;
    final accent = color == null
        ? scheme.outline
        : LiturgicalPalette.accent(color, theme.brightness);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liturgia de hoy'),
        actions: [
          IconButton(
            tooltip: 'Fuente y alcance',
            onPressed: () =>
                showLiturgySourceSheet(context, day: day, selection: selection),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateLabel(day.date),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                day.primary.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    accent.withValues(alpha: 0.08),
                    scheme.surface,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  children: [
                    _Fact(label: 'Tiempo', value: _seasonLabel(day.season)),
                    _Fact(label: 'Rango', value: _rankLabel(day.primary.rank)),
                    _Fact(
                      label: 'Color',
                      value: color == null
                          ? 'Sin color indicado'
                          : LiturgicalPalette.label(color),
                    ),
                    if (day.sundayCycle != null)
                      _Fact(label: 'Ciclo dominical', value: day.sundayCycle!),
                    if (day.weekdayCycle != null)
                      _Fact(label: 'Ciclo ferial', value: day.weekdayCycle!),
                    if (day.psalterWeek != null)
                      _Fact(
                        label: 'Salterio',
                        value: 'Semana ${day.psalterWeek}',
                      ),
                  ],
                ),
              ),
              if (day.optional.isNotEmpty) ...[
                const SizedBox(height: 26),
                Text('Memorias opcionales', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                ...day.optional.map(
                  (celebration) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.auto_awesome, color: accent, size: 20),
                    title: Text(celebration.name),
                    subtitle: Text(_rankLabel(celebration.rank)),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: accent),
                    const SizedBox(height: 10),
                    Text(
                      'Oración devocional sugerida para hoy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tómate un momento para presentar este día a Dios con tus propias palabras.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => showLiturgySourceSheet(
                  context,
                  day: day,
                  selection: selection,
                ),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Fuente y alcance del calendario'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    const months = [
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
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  static String _seasonLabel(LiturgicalSeason season) => switch (season) {
    LiturgicalSeason.advent => 'Adviento',
    LiturgicalSeason.christmas => 'Navidad',
    LiturgicalSeason.ordinaryTime => 'Tiempo Ordinario',
    LiturgicalSeason.lent => 'Cuaresma',
    LiturgicalSeason.triduum => 'Triduo Pascual',
    LiturgicalSeason.easter => 'Pascua',
  };

  static String _rankLabel(LiturgicalRank rank) => switch (rank) {
    LiturgicalRank.solemnity => 'Solemnidad',
    LiturgicalRank.sunday => 'Domingo',
    LiturgicalRank.feast => 'Fiesta',
    LiturgicalRank.memorial => 'Memoria',
    LiturgicalRank.optionalMemorial => 'Memoria opcional',
    LiturgicalRank.weekday => 'Feria',
  };
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 112, maxWidth: 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
