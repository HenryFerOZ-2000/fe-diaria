import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';

/// Titular en dos tonos: [lead] en tinta y [accent] en índigo.
/// "Oraciones" + "para cada momento".
class VTwoToneTitle extends StatelessWidget {
  const VTwoToneTitle(
    this.lead,
    this.accent, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String lead;
  final String accent;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
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
