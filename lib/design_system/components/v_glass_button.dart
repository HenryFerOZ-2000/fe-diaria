import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

/// Botón cuadrado translúcido para usar sobre fotos y portadas.
class VGlassButton extends StatelessWidget {
  const VGlassButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 46,
  });

  final VerbumIcons icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(VerbumRadius.control);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .2),
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: size,
            child: Center(child: VIcon(icon, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
