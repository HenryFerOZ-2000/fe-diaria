import 'package:flutter/material.dart';

import '../../../controllers/missions_controller.dart';
import '../../../design_system/design_system.dart';
import 'mission_visuals.dart';

/// Los momentos esenciales del día como tiles: hecho, siguiente, pendiente.
class JourneyStepsRow extends StatelessWidget {
  const JourneyStepsRow({
    super.key,
    required this.missions,
    required this.nextMission,
    required this.onOpen,
  });

  final List<Mission> missions;
  final Mission? nextMission;
  final ValueChanged<Mission> onOpen;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < missions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: VStepTile(
                icon: iconForMission(missions[i]),
                title: shortLabelForMission(missions[i]),
                caption: missions[i].completed
                    ? 'Hecho'
                    : '${missions[i].durationMinutes} min',
                state: missions[i].completed
                    ? VStepState.done
                    : identical(missions[i], nextMission)
                    ? VStepState.current
                    : VStepState.upcoming,
                onTap: () => onOpen(missions[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
