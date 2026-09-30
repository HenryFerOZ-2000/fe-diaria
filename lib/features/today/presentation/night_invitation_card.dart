import 'package:flutter/material.dart';

import '../../../controllers/missions_controller.dart';
import '../../../design_system/design_system.dart';
import '../application/today_schedule.dart';

/// Invitación opcional a la oración de la noche (Completas), en tono tinta.
class NightInvitationCard extends StatelessWidget {
  const NightInvitationCard({
    super.key,
    required this.mission,
    required this.available,
    required this.onOpen,
  });

  final Mission mission;
  final bool available;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final open = available || mission.completed;
    return VActionTile(
      tone: VSurfaceTone.ink,
      icon: mission.completed ? VerbumIcons.checkCircle : VerbumIcons.moonStars,
      overline: mission.completed
          ? 'Cierre del día completado'
          : 'Para esta noche · Opcional',
      title: mission.title,
      subtitle: open
          ? '${mission.durationMinutes} min · ${mission.description}'
          : 'Disponible desde las $nightPrayerStartHour:00',
      trailingIcon: open ? VerbumIcons.arrowRight : VerbumIcons.lockSimple,
      onTap: open ? onOpen : null,
    );
  }
}
