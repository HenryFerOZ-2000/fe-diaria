import 'package:flutter/material.dart';

import '../../../faith/faith_tradition.dart';
import '../domain/calendar_selection.dart';

class CatholicCalendarSettingsTile extends StatelessWidget {
  const CatholicCalendarSettingsTile({
    super.key,
    required this.tradition,
    required this.selection,
    required this.onChanged,
  });

  final FaithTradition tradition;
  final CalendarSelection selection;
  final ValueChanged<CalendarSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    if (tradition != FaithTradition.catholic) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isEcuador = selection.countryCode == 'EC';
    return Semantics(
      button: true,
      label: 'Calendario católico',
      child: InkWell(
        onTap: () => _showSelection(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.public_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendario católico',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEcuador
                          ? 'Ecuador · recomendado para ti'
                          : 'Calendario Romano General',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isEcuador) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Contenido local aún no disponible; se usa el Calendario Romano General.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSelection(BuildContext context) async {
    final chosen = await showModalBottomSheet<CalendarSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Text(
                  'Calendario católico',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _CalendarOption(
                title: 'Ecuador',
                subtitle:
                    'Aplicaremos contenido ecuatoriano únicamente cuando esté verificado.',
                selected: selection.countryCode == 'EC',
                onTap: () =>
                    Navigator.pop(context, CalendarSelection.country('EC')),
              ),
              _CalendarOption(
                title: 'Calendario Romano General',
                subtitle: 'Calendario base mundial, disponible sin conexión.',
                selected: selection.isGeneralRoman,
                onTap: () => Navigator.pop(
                  context,
                  const CalendarSelection.generalRoman(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) onChanged(chosen);
  }
}

class _CalendarOption extends StatelessWidget {
  const _CalendarOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: ListTile(
        minVerticalPadding: 12,
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
