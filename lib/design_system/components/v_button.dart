import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

enum VButtonVariant {
  /// Tinta sólida: la acción principal de la pantalla.
  solid,

  /// Filete fino: acción secundaria.
  outlined,

  /// Solo texto en rojo rúbrica: acción terciaria.
  text,

  /// Papel sobre superficies en tinta (p. ej. dentro de VFeatureCard).
  inverse,
}

/// Botón de la app con icono opcional (a la derecha por defecto, como una
/// invitación a avanzar: "Comenzar →").
class VButton extends StatelessWidget {
  const VButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconLeading = false,
    this.variant = VButtonVariant.solid,
    this.expanded = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final VerbumIcons? icon;
  final bool iconLeading;
  final VButtonVariant variant;

  /// Ocupa todo el ancho disponible.
  final bool expanded;

  /// Altura reducida para usar dentro de tarjetas.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      VButtonVariant.solid => (p.ink, p.onInk, BorderSide.none),
      VButtonVariant.outlined => (
        Colors.transparent,
        p.ink,
        BorderSide(color: p.line, width: 1.2),
      ),
      VButtonVariant.text => (Colors.transparent, p.rubric, BorderSide.none),
      VButtonVariant.inverse => (p.onInk, p.ink, BorderSide.none),
    };
    final enabled = onPressed != null;
    final color = enabled ? fg : p.inkSubtle;

    final children = <Widget>[
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.button.copyWith(
            color: color,
            fontSize: compact ? 13 : null,
          ),
        ),
      ),
      if (icon != null) ...[
        const SizedBox(width: 8),
        VIcon(icon!, size: compact ? 16 : 18, color: color),
      ],
    ];

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: iconLeading ? children.reversed.toList() : children,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled || variant != VButtonVariant.solid ? bg : p.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            compact ? 99 : VerbumRadius.control,
          ),
          side: side,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 40 : 50),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
