import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';

class VSegment<T> {
  const VSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// Selector de opciones excluyentes: la elegida en tinta sobre papel.
class VSegmentedControl<T> extends StatelessWidget {
  const VSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<VSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(VerbumRadius.control + 2),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: Semantics(
                button: true,
                selected: segment.value == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(segment.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: segment.value == selected
                          ? p.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        VerbumRadius.control - 2,
                      ),
                      border: segment.value == selected
                          ? Border.all(color: p.line)
                          : null,
                    ),
                    child: Text(
                      segment.label,
                      textAlign: TextAlign.center,
                      style: type.caption.copyWith(
                        color: segment.value == selected ? p.ink : p.inkMuted,
                        fontWeight: segment.value == selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
