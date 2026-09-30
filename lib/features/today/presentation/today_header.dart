import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../application/today_schedule.dart';

/// Encabezado de "Hoy": fecha e invitación en rúbrica, saludo en serif.
class TodayHeader extends StatelessWidget {
  const TodayHeader({
    super.key,
    required this.now,
    this.userName,
    this.actions,
  });

  final DateTime now;
  final String? userName;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final p = context.palette;
    final greeting = greetingFor(now, name: userName);
    final name = firstName(userName);
    final comma = greeting.indexOf(',');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${shortSpanishDate(now)} · ${dayInvitationFor(now)}'
                    .toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.rubric.copyWith(
                  color: p.inkSubtle,
                  fontSize: 9.5,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name == null
                            ? greeting
                            : greeting.substring(0, comma + 1),
                      ),
                      if (name != null)
                        TextSpan(
                          text: ' $name',
                          style: TextStyle(
                            color: p.rubric,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.title,
                ),
              ),
            ],
          ),
        ),
        if (actions != null) ...[const SizedBox(width: 12), actions!],
      ],
    );
  }
}
