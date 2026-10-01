import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../icons/verbum_icons.dart';

/// Peso visual del icono. Regla: [regular] en reposo, [fill] cuando está
/// activo/seleccionado, [duotone] en ilustraciones y tiles de categoría.
enum VIconWeight { regular, fill, duotone }

/// Icono SVG de Phosphor. Toma color y tamaño del [IconTheme] si no se pasan,
/// así funciona dentro de `NavigationBar`, `ListTile`, botones, etc.
class VIcon extends StatelessWidget {
  const VIcon(
    this.icon, {
    super.key,
    this.weight = VIconWeight.regular,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final VerbumIcons icon;
  final VIconWeight weight;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  static String assetPath(VerbumIcons icon, VIconWeight weight) =>
      'assets/icons/phosphor/${weight.name}/${icon.asset}.svg';

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final resolvedSize = size ?? theme.size ?? 24;
    final resolvedColor =
        color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    final picture = SvgPicture.asset(
      assetPath(icon, weight),
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      excludeFromSemantics: semanticLabel == null,
      semanticsLabel: semanticLabel,
    );
    return SizedBox.square(dimension: resolvedSize, child: picture);
  }
}
