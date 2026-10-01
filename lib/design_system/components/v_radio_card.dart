import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

/// Opción única con título y descripción (tradición, plan, modo…).
class VRadioCard extends StatelessWidget {
  const VRadioCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final VerbumIcons icon;
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: description == null ? title : '$title. $description',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? p.accentSoft : p.surface,
          borderRadius: BorderRadius.circular(VerbumRadius.card - 2),
          border: Border.all(
            color: selected ? p.rubric : p.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(VerbumRadius.card - 2),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  VIcon(
                    icon,
                    weight: VIconWeight.duotone,
                    size: 32,
                    color: selected ? p.rubric : p.gold,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: type.bodyStrong.copyWith(fontSize: 15),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 3),
                          Text(description!, style: type.caption),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? p.rubric : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? p.rubric : p.line,
                        width: 1.4,
                      ),
                    ),
                    child: selected
                        ? VIcon(VerbumIcons.check, size: 14, color: p.surface)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
