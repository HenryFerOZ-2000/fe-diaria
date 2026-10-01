import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../design_system/design_system.dart';

/// Un versículo listo para mostrar.
typedef ChapterVerse = ({int number, String text});

/// Trozo del capítulo: el número volado de un versículo o parte de su texto.
class _Piece {
  /// El número va unido a su versículo por un espacio fino que no se corta:
  /// nunca queda solo al final de una línea.
  _Piece.number(this.verse) : text = '$verse\u202F', isNumber = true;
  const _Piece.text(this.verse, this.text) : isNumber = false;

  final int verse;
  final String text;
  final bool isNumber;

  int get length => text.length;
}

/// El capítulo como texto corrido, a la manera de un libro: capitular al
/// inicio (si empieza en el versículo 1) y números volados. Cada versículo
/// se toca para seleccionarlo; los resaltados llevan franja mantequilla.
class ChapterText extends StatefulWidget {
  const ChapterText({
    super.key,
    required this.verses,
    required this.fontSize,
    required this.lineHeight,
    required this.textColor,
    required this.selected,
    required this.highlighted,
    required this.onTap,
    this.justify = false,
  });

  final List<ChapterVerse> verses;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Set<int> selected;
  final Set<int> highlighted;
  final ValueChanged<int> onTap;

  /// Justificado opcional; por defecto alineado a la izquierda.
  final bool justify;

  @override
  State<ChapterText> createState() => ChapterTextState();
}

class ChapterTextState extends State<ChapterText> {
  static const _capLines = 2;
  static const _capGap = 8.0;

  /// Párrafo junto a la capitular y párrafo a todo el ancho.
  final _paragraphKeys = [GlobalKey(), GlobalKey()];
  final Map<int, TapGestureRecognizer> _recognizers = {};

  /// Dónde está cada versículo: párrafo, inicio y fin.
  final Map<int, (int, int, int)> _ranges = {};

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizer(int verse) =>
      _recognizers.putIfAbsent(verse, TapGestureRecognizer.new)
        ..onTap = () => widget.onTap(verse);

  RenderParagraph? _paragraph(int index) =>
      _paragraphKeys[index].currentContext?.findRenderObject()
          as RenderParagraph?;

  /// Rectángulo del versículo y el párrafo que lo contiene.
  (RenderParagraph, Rect)? _locate(int verse) {
    final range = _ranges[verse];
    if (range == null) return null;
    final paragraph = _paragraph(range.$1);
    if (paragraph == null || !paragraph.attached) return null;
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: range.$2, extentOffset: range.$3),
    );
    if (boxes.isEmpty) return null;
    final rect = boxes
        .map((b) => b.toRect())
        .reduce((a, b) => a.expandToInclude(b));
    return (paragraph, rect);
  }

  /// Altura global del comienzo de [verse] (para guardar la posición).
  double? verseTop(int verse) {
    final found = _locate(verse);
    if (found == null) return null;
    return found.$1.localToGlobal(found.$2.topLeft).dy;
  }

  /// Desplaza la página hasta [verse].
  void showVerse(int verse, {Duration duration = Duration.zero}) {
    final found = _locate(verse);
    found?.$1.showOnScreen(
      rect: found.$2.inflate(48),
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textScaler = MediaQuery.textScalerOf(context);
    // Mismo estilo efectivo que usará Text.rich, para que la medición de
    // las líneas junto a la capitular coincida con lo que se pinta.
    final style = DefaultTextStyle.of(context).style.merge(
      VerbumFonts.serif(
        color: widget.textColor,
        fontSize: widget.fontSize,
        height: widget.lineHeight,
        fontWeight: FontWeight.w500,
      ),
    );
    // Cifras voladas en periwinkle.
    final numberStyle = VerbumFonts.sans(
      color: p.gold,
      fontSize: widget.fontSize * .62,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.superscripts()],
    );
    final lineHeight = widget.fontSize * widget.lineHeight;
    final capStyle = style.copyWith(
      fontSize: lineHeight * _capLines * 0.92,
      height: 1,
      fontWeight: FontWeight.w600,
      color: p.rubric,
    );

    // Capitular solo cuando el capítulo empieza de verdad (versículo 1).
    final first = widget.verses.firstOrNull;
    final dropCap = first != null && first.number == 1 && first.text.isNotEmpty;
    final cap = dropCap ? first.text.characters.first : '';

    final pieces = <_Piece>[
      for (final v in widget.verses) ...[
        if (!(dropCap && identical(v, first))) _Piece.number(v.number),
        _Piece.text(
          v.number,
          dropCap && identical(v, first)
              ? '${v.text.characters.skip(1).toString().trimLeft()} '
              : '${v.text} ',
        ),
      ],
    ];

    InlineSpan span(_Piece piece, String text) {
      if (piece.isNumber) {
        return TextSpan(
          text: text,
          recognizer: _recognizer(piece.verse),
          style: numberStyle,
        );
      }
      final selected = widget.selected.contains(piece.verse);
      final highlighted = widget.highlighted.contains(piece.verse);
      return TextSpan(
        text: text,
        recognizer: _recognizer(piece.verse),
        style: TextStyle(
          backgroundColor: selected
              ? p.gold.withValues(alpha: .18)
              : highlighted
              ? p.goldSoft
              : null,
          decoration: selected ? TextDecoration.underline : null,
          decorationColor: p.rubric,
          decorationStyle: TextDecorationStyle.dotted,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        var split = pieces.fold(0, (n, piece) => n + piece.length);
        double capWidth = 0;
        if (dropCap) {
          final capPainter = TextPainter(
            text: TextSpan(text: cap, style: capStyle),
            textDirection: TextDirection.ltr,
            textScaler: textScaler,
          )..layout();
          capWidth = capPainter.width;
          capPainter.dispose();
          split = _splitAfterLines(
            pieces,
            style: style,
            textScaler: textScaler,
            maxWidth: constraints.maxWidth - capWidth - _capGap,
            span: (piece) => span(piece, piece.text),
          );
        }

        // Reparte los trozos entre los dos párrafos y anota los rangos.
        final parts = [<InlineSpan>[], <InlineSpan>[]];
        final offsets = [0, 0];
        _ranges.clear();
        var offset = 0;
        for (final piece in pieces) {
          final cuts = <(int, String)>[];
          if (piece.isNumber) {
            cuts.add((offset < split ? 0 : 1, piece.text));
          } else if (offset + piece.length <= split) {
            cuts.add((0, piece.text));
          } else if (offset >= split) {
            cuts.add((1, piece.text));
          } else {
            cuts
              ..add((0, piece.text.substring(0, split - offset)))
              ..add((1, piece.text.substring(split - offset)));
          }
          for (final (para, text) in cuts) {
            // El párrafo de abajo no empieza con un espacio.
            final shown = para == 1 && offsets[1] == 0 ? text.trimLeft() : text;
            if (shown.isEmpty) continue;
            final length = shown.length;
            final start = offsets[para];
            final range = _ranges[piece.verse];
            if (range == null) {
              _ranges[piece.verse] = (para, start, start + length);
            } else if (range.$1 == para) {
              _ranges[piece.verse] = (para, range.$2, start + length);
            }
            parts[para].add(span(piece, shown));
            offsets[para] += length;
          }
          offset += piece.length;
        }

        final below = Text.rich(
          TextSpan(children: parts[1]),
          key: _paragraphKeys[1],
          style: style,
          textAlign: widget.justify ? TextAlign.justify : TextAlign.start,
        );
        if (!dropCap) {
          return Text.rich(
            TextSpan(children: parts[0]),
            key: _paragraphKeys[0],
            style: style,
            textAlign: widget.justify ? TextAlign.justify : TextAlign.start,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    right: _capGap,
                    top: lineHeight * 0.08,
                  ),
                  child: ExcludeSemantics(
                    child: Text(cap, style: capStyle, textScaler: textScaler),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: parts[0]),
                    key: _paragraphKeys[0],
                    style: style,
                    textAlign: widget.justify
                        ? TextAlign.justify
                        : TextAlign.start,
                  ),
                ),
              ],
            ),
            if (parts[1].isNotEmpty) below,
          ],
        );
      },
    );
  }

  /// Desplazamiento (en caracteres) donde terminan las líneas que caben
  /// junto a la capitular.
  int _splitAfterLines(
    List<_Piece> pieces, {
    required TextStyle style,
    required TextScaler textScaler,
    required double maxWidth,
    required InlineSpan Function(_Piece) span,
  }) {
    final total = pieces.fold(0, (n, piece) => n + piece.length);
    final painter = TextPainter(
      text: TextSpan(children: [for (final p in pieces) span(p)], style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );
    painter.layout(maxWidth: maxWidth.clamp(1, double.infinity));
    final lines = painter.computeLineMetrics();
    var split = total;
    if (lines.length > _capLines) {
      final bottom = lines
          .take(_capLines)
          .fold<double>(0, (sum, line) => sum + line.height);
      final position = painter.getPositionForOffset(
        Offset(maxWidth, bottom - 1),
      );
      split = painter.getLineBoundary(position).end;
    }
    painter.dispose();
    return split;
  }
}
