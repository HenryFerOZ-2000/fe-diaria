import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../design_system/design_system.dart';

/// Un versículo listo para mostrar.
typedef ChapterVerse = ({int number, String text});

/// El capítulo como texto corrido, con números volados en índigo.
/// Cada versículo se toca para seleccionarlo; los resaltados llevan
/// fondo mantequilla.
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
  });

  final List<ChapterVerse> verses;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Set<int> selected;
  final Set<int> highlighted;
  final ValueChanged<int> onTap;

  @override
  State<ChapterText> createState() => ChapterTextState();
}

class ChapterTextState extends State<ChapterText> {
  final _textKey = GlobalKey();
  final Map<int, TapGestureRecognizer> _recognizers = {};

  /// Inicio y fin de cada versículo dentro del texto plano.
  final Map<int, (int, int)> _ranges = {};

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _recognizer(int verse) =>
      _recognizers.putIfAbsent(verse, () => TapGestureRecognizer())
        ..onTap = () => widget.onTap(verse);

  RenderParagraph? get _paragraph =>
      _textKey.currentContext?.findRenderObject() as RenderParagraph?;

  /// Rectángulo del versículo, en coordenadas del párrafo.
  Rect? verseRect(int verse) {
    final paragraph = _paragraph;
    final range = _ranges[verse];
    if (paragraph == null || range == null || !paragraph.attached) return null;
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: range.$1, extentOffset: range.$2),
    );
    if (boxes.isEmpty) return null;
    return boxes.map((b) => b.toRect()).reduce((a, b) => a.expandToInclude(b));
  }

  /// Altura global del comienzo de [verse] (para guardar la posición).
  double? verseTop(int verse) {
    final rect = verseRect(verse);
    final paragraph = _paragraph;
    if (rect == null || paragraph == null) return null;
    return paragraph.localToGlobal(rect.topLeft).dy;
  }

  /// Desplaza la página hasta [verse].
  void showVerse(int verse, {Duration duration = Duration.zero}) {
    final rect = verseRect(verse);
    if (rect == null) return;
    _paragraph?.showOnScreen(
      rect: rect.inflate(48),
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = VerbumFonts.serif(
      color: widget.textColor,
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      fontStyle: FontStyle.italic,
    );
    final numberStyle = VerbumFonts.sans(
      color: p.gold,
      fontSize: (widget.fontSize * .52).clamp(9, 13).toDouble(),
      fontWeight: FontWeight.w800,
    );

    _ranges.clear();
    var offset = 0;
    final spans = <InlineSpan>[];
    for (final v in widget.verses) {
      final selected = widget.selected.contains(v.number);
      final highlighted = widget.highlighted.contains(v.number);
      // El número cuenta como un carácter (marcador de widget).
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text('${v.number}', style: numberStyle),
          ),
        ),
      );
      final text = '${v.text} ';
      _ranges[v.number] = (offset, offset + 1 + v.text.length);
      offset += 1 + text.length;
      spans.add(
        TextSpan(
          text: text,
          recognizer: _recognizer(v.number),
          semanticsLabel: 'Versículo ${v.number}. ${v.text}',
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
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      key: _textKey,
      style: style,
    );
  }
}
