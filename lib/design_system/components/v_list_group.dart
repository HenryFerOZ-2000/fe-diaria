import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

/// Fila de una [VListGroup]. Construida sobre [Material]/[InkWell], así el
/// efecto de toque se ve sobre el papel (a diferencia de ListTile dentro de
/// un contenedor con color).
class VListRow extends StatelessWidget {
  const VListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingColor,
    this.trailing = VerbumIcons.caretRight,
    this.trailingWidget,
    this.value,
    this.onTap,
    this.semanticHint,
  });

  final String title;
  final String? subtitle;
  final VerbumIcons? leading;
  final Color? leadingColor;
  final VerbumIcons? trailing;

  /// Sustituye al icono final (interruptor, botones − / +…).
  final Widget? trailingWidget;

  /// Valor actual a la derecha, antes de la flecha ("Español").
  final String? value;
  final VoidCallback? onTap;

  /// Qué ocurre al tocar, para lectores de pantalla ("Abre el navegador").
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Semantics(
      button: onTap != null,
      hint: semanticHint,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (leading != null) ...[
                  VIcon(
                    leading!,
                    weight: VIconWeight.duotone,
                    size: 22,
                    color: leadingColor ?? p.gold,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: type.bodyStrong),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: type.caption),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: type.body.copyWith(color: p.inkMuted),
                    ),
                  ),
                ],
                if (trailingWidget != null)
                  trailingWidget!
                else if (trailing != null) ...[
                  const SizedBox(width: 8),
                  VIcon(trailing!, size: 16, color: p.inkSubtle),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila con interruptor: toda la fila alterna el valor.
class VSwitchRow extends StatelessWidget {
  const VSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.leadingColor,
  });

  final String title;
  final String? subtitle;
  final VerbumIcons? leading;
  final Color? leadingColor;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: VListRow(
        title: title,
        subtitle: subtitle,
        leading: leading,
        leadingColor: leadingColor,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        trailingWidget: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Switch.adaptive(value: value, onChanged: onChanged),
        ),
      ),
    );
  }
}

/// Grupo de filas sobre papel con filetes entre ellas y rúbrica opcional.
class VListGroup extends StatelessWidget {
  const VListGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbumRadius.card - 4),
        side: BorderSide(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                title!.toUpperCase(),
                style: context.type.rubric.copyWith(fontSize: 9.5),
              ),
            ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 16, endIndent: 16, color: p.lineSoft),
            children[i],
          ],
        ],
      ),
    );
  }
}
