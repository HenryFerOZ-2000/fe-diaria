import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import 'v_icon.dart';

/// Etiqueta en versalitas espaciadas, como las rúbricas de un misal.
/// Ej.: "Palabra del día", "Continúa · día 9 de 9".
class VRubricLabel extends StatelessWidget {
  const VRubricLabel(this.text, {super.key, this.icon, this.color});

  final String text;
  final VerbumIcons? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = context.type.rubric.copyWith(color: color);
    final label = Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VIcon(icon!, weight: VIconWeight.fill, size: 14, color: style.color),
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }
}
