import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';

/// Titular en dos tonos: [lead] en tinta y [accent] en periwinkle.
/// Con [accentFirst] el tono claro va delante: "Ora por" + "lo que vives hoy".
class VTwoToneTitle extends StatelessWidget {
  const VTwoToneTitle(
    this.lead,
    this.accent, {
    super.key,
    this.style,
    this.textAlign,
    this.accentFirst = false,
  });

  final String lead;
  final String accent;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool accentFirst;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          children: accentFirst
              ? [
                  TextSpan(
                    text: '$accent ',
                    style: TextStyle(color: p.gold),
                  ),
                  TextSpan(text: lead),
                ]
              : [
                  TextSpan(text: '$lead '),
                  TextSpan(
                    text: accent,
                    style: TextStyle(color: p.gold),
                  ),
                ],
        ),
        textAlign: textAlign,
        style: style ?? context.type.display,
      ),
    );
  }
}
