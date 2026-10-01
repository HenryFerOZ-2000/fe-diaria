import 'package:flutter/material.dart';

import '../../../faith/faith_tradition.dart';
import '../domain/calendar_selection.dart';
import 'package:verbum/design_system/design_system.dart';

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

    final isEcuador = selection.countryCode == 'EC';
    final row = VListRow(
      leading: VerbumIcons.calendarDots,
      title: 'Calendario católico',
      subtitle: isEcuador
          ? 'Ecuador · recomendado para ti'
          : 'Calendario Romano General',
      onTap: () => _showSelection(context),
    );
    if (!isEcuador) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(50, 0, 16, 12),
          child: Text(
            'Contenido local aún no disponible; se usa el Calendario Romano General.',
            style: context.type.caption,
          ),
        ),
      ],
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
        leading: VIcon(
          selected ? VerbumIcons.radioButton : VerbumIcons.circle,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
