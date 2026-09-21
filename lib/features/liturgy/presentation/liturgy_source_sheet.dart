import 'package:flutter/material.dart';

import '../../../widgets/source_link.dart';
import '../domain/calendar_selection.dart';
import '../domain/liturgical_day.dart';
import '../domain/liturgical_source.dart';

Future<void> showLiturgySourceSheet(
  BuildContext context, {
  required LiturgicalDay day,
  required CalendarSelection selection,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _LiturgySourceContent(day: day, selection: selection),
  );
}

class _LiturgySourceContent extends StatelessWidget {
  const _LiturgySourceContent({required this.day, required this.selection});

  final LiturgicalDay day;
  final CalendarSelection selection;

  @override
  Widget build(BuildContext context) {
    final source = day.source;
    final usesGeneralFallback =
        selection.countryCode == 'EC' &&
        source.scope == CalendarScope.generalRoman;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fuente y alcance', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 18),
            Text(
              _scopeLabel(source.scope),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              source.reviewNotes,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (usesGeneralFallback) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'El contenido local de Ecuador aún no está disponible; hoy se usa el Calendario Romano General.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _SourceRow(label: 'Proveedor', value: source.name),
            _SourceRow(label: 'Licencia', value: source.license),
            _SourceRow(label: 'Revisado', value: source.reviewedAt),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openSource(context, source.url),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Consultar la fuente'),
            ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel(CalendarScope scope) => switch (scope) {
    CalendarScope.generalRoman => 'Calendario Romano General',
    CalendarScope.americas => 'Calendario de América',
    CalendarScope.country => 'Calendario nacional',
    CalendarScope.diocesan => 'Calendario diocesano',
  };
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
