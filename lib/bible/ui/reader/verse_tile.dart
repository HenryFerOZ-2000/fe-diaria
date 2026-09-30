import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Un versículo en la página de lectura. El primero del capítulo abre con
/// capitular; el resto lleva su número en rojo rúbrica.
class VerseTile extends StatelessWidget {
  const VerseTile({
    super.key,
    required this.number,
    required this.text,
    required this.fontSize,
    required this.lineHeight,
    required this.textColor,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  final int number;
  final String text;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = VerbumFonts.serif(
      color: textColor,
      fontSize: fontSize,
      height: lineHeight,
    );
    final numberStyle = VerbumFonts.sans(
      color: p.rubric,
      fontSize: (fontSize * .55).clamp(9, 13).toDouble(),
      fontWeight: FontWeight.w800,
    );

    final body = number == 1
        ? VDropCapText(text, style: style, capLines: 2)
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$number  ', style: numberStyle),
                TextSpan(text: text),
              ],
            ),
            style: style,
          );

    return Semantics(
      selected: selected,
      button: true,
      label: 'Versículo $number. $text',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? p.gold.withValues(alpha: .16)
                : highlighted
                ? p.goldSoft.withValues(alpha: .7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border(left: BorderSide(color: p.rubric, width: 2.5))
                : null,
          ),
          child: body,
        ),
      ),
    );
  }
}
