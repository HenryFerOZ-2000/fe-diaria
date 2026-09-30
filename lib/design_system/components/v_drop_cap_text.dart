import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';

/// Párrafo con capitular (primera letra grande en rojo rúbrica), como en los
/// libros iluminados. El texto fluye junto a la capitular y continúa debajo a
/// todo el ancho.
class VDropCapText extends StatelessWidget {
  const VDropCapText(
    this.text, {
    super.key,
    this.style,
    this.capColor,
    this.capLines = 2,
    this.gap = 8,
  });

  final String text;
  final TextStyle? style;
  final Color? capColor;

  /// Cuántas líneas de texto ocupa la capitular.
  final int capLines;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final bodyStyle = DefaultTextStyle.of(
      context,
    ).style.merge(style ?? context.type.scripture);
    final textScaler = MediaQuery.textScalerOf(context);
    final fontSize = bodyStyle.fontSize ?? 16;
    final lineHeight = fontSize * (bodyStyle.height ?? 1.3);
    final capStyle = bodyStyle.copyWith(
      fontSize: lineHeight * capLines * 0.92,
      height: 1,
      fontWeight: FontWeight.w600,
      color: capColor ?? context.palette.rubric,
    );

    final cap = trimmed.characters.first;
    final rest = trimmed.characters.skip(1).toString();
    final direction = Directionality.of(context);

    return Semantics(
      label: trimmed,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final capPainter = TextPainter(
            text: TextSpan(text: cap, style: capStyle),
            textDirection: direction,
            textScaler: textScaler,
          )..layout();
          final besideWidth = (constraints.maxWidth - capPainter.width - gap)
              .clamp(0.0, double.infinity);

          final restPainter = TextPainter(
            text: TextSpan(text: rest, style: bodyStyle),
            textDirection: direction,
            textScaler: textScaler,
          )..layout(maxWidth: besideWidth);
          final metrics = restPainter.computeLineMetrics();

          var splitAt = rest.length;
          if (metrics.length > capLines) {
            final bottom = metrics
                .take(capLines)
                .fold<double>(0, (sum, line) => sum + line.height);
            final position = restPainter.getPositionForOffset(
              Offset(besideWidth, bottom - 1),
            );
            splitAt = restPainter.getLineBoundary(position).end;
          }
          capPainter.dispose();
          restPainter.dispose();

          final beside = rest.substring(0, splitAt);
          final below = rest.substring(splitAt).trimLeft();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: gap,
                      top: lineHeight * 0.08,
                    ),
                    child: Text(cap, style: capStyle, textScaler: textScaler),
                  ),
                  Expanded(child: Text(beside, style: bodyStyle)),
                ],
              ),
              if (below.isNotEmpty) Text(below, style: bodyStyle),
            ],
          );
        },
      ),
    );
  }
}
