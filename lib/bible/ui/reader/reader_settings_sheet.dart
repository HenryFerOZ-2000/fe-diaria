import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../application/reader_tone.dart';
import 'reader_colors.dart';

/// Ajustes de lectura: tamaño, interlineado y tono de página.
/// No guarda nada: avisa por callbacks y la pantalla persiste.
class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({
    super.key,
    required this.fontSize,
    required this.lineHeight,
    required this.tone,
    required this.onFontSize,
    required this.onFontSizeEnd,
    required this.onLineHeight,
    required this.onLineHeightEnd,
    required this.onTone,
    this.justify = false,
    this.onJustify,
  });

  final double fontSize;
  final double lineHeight;
  final ReaderTone tone;
  final ValueChanged<double> onFontSize;
  final ValueChanged<double> onFontSizeEnd;
  final ValueChanged<double> onLineHeight;
  final ValueChanged<double> onLineHeightEnd;
  final ValueChanged<ReaderTone> onTone;
  final bool justify;
  final ValueChanged<bool>? onJustify;

  static const minFont = 15.0, maxFont = 25.0;
  static const minLine = 1.35, maxLine = 1.95;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late double _font = widget.fontSize;
  late double _line = widget.lineHeight;
  late ReaderTone _tone = widget.tone;
  late bool _justify = widget.justify;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu espacio de lectura',
            style: type.title.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text('Ajusta la página para leer con calma.', style: type.body),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('A', style: VerbumFonts.serif(fontSize: 15, color: p.ink)),
              Expanded(
                child: Slider(
                  value: _font,
                  min: ReaderSettingsSheet.minFont,
                  max: ReaderSettingsSheet.maxFont,
                  divisions: 10,
                  label: 'Tamaño ${_font.round()}',
                  onChanged: (v) {
                    setState(() => _font = v);
                    widget.onFontSize(v);
                  },
                  onChangeEnd: widget.onFontSizeEnd,
                ),
              ),
              Text('A', style: VerbumFonts.serif(fontSize: 25, color: p.ink)),
            ],
          ),
          Row(
            children: [
              VIcon(VerbumIcons.textAa, size: 20, color: p.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _line,
                  min: ReaderSettingsSheet.minLine,
                  max: ReaderSettingsSheet.maxLine,
                  divisions: 4,
                  label: 'Interlineado',
                  onChanged: (v) {
                    setState(() => _line = v);
                    widget.onLineHeight(v);
                  },
                  onChangeEnd: widget.onLineHeightEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (tone, label) in const [
                (ReaderTone.system, 'Vitela'),
                (ReaderTone.warm, 'Cálido'),
                (ReaderTone.night, 'Noche'),
              ]) ...[
                if (tone != ReaderTone.system) const SizedBox(width: 9),
                Expanded(
                  child: _ToneOption(
                    label: label,
                    colors: ReaderColors.of(context, tone),
                    selected: _tone == tone,
                    onTap: () {
                      setState(() => _tone = tone);
                      widget.onTone(tone);
                    },
                  ),
                ),
              ],
            ],
          ),
          if (widget.onJustify != null) ...[
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Justificar texto', style: type.bodyStrong),
              subtitle: Text(
                'Aspecto de libro impreso. Sin justificar se lee mejor en '
                'pantallas pequeñas.',
                style: type.caption,
              ),
              activeTrackColor: p.emphasis,
              value: _justify,
              onChanged: (v) {
                setState(() => _justify = v);
                widget.onJustify!(v);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ToneOption extends StatelessWidget {
  const _ToneOption({
    required this.label,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ReaderColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tono $label',
      excludeSemantics: true,
      child: Material(
        color: colors.page,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VerbumRadius.control),
          side: BorderSide(
            color: selected ? p.rubric : p.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Center(
              child: Text(
                label,
                style: context.type.bodyStrong.copyWith(
                  color: colors.text,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
