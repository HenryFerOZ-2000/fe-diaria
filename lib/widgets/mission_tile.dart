import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tile de misión diaria con check animado.
class MissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool completed;
  final VoidCallback onToggle;

  const MissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.completed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: completed
            ? colorScheme.primary.withOpacity(0.12)
            : colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? colorScheme.primary.withOpacity(0.35)
              : colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(completed ? 0.18 : 0.08),
            blurRadius: completed ? 12 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onToggle,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: completed
                    ? colorScheme.primary.withOpacity(0.18)
                    : colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: completed
                  ? Icon(Icons.check_circle, color: colorScheme.primary, key: const ValueKey('done'))
                  : Icon(Icons.circle_outlined, color: colorScheme.outline, key: const ValueKey('todo')),
            ),
          ],
        ),
      ),
    );
  }
}

