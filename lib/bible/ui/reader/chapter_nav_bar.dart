import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Navegación entre capítulos al pie del lector.
class ChapterNavBar extends StatelessWidget {
  const ChapterNavBar({
    super.key,
    required this.chapter,
    required this.lastChapter,
    required this.onOpen,
  });

  final int chapter;
  final int lastChapter;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  // Sin heightFactor, Align ocuparía toda la altura del Scaffold.
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: VButton(
                    label: 'Anterior',
                    icon: VerbumIcons.arrowLeft,
                    iconLeading: true,
                    variant: VButtonVariant.text,
                    compact: true,
                    onPressed: chapter > 1 ? () => onOpen(chapter - 1) : null,
                  ),
                ),
              ),
              Text(
                '$chapter de $lastChapter',
                style: type.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: p.inkMuted,
                ),
              ),
              Expanded(
                child: Align(
                  heightFactor: 1,
                  alignment: Alignment.centerRight,
                  child: VButton(
                    label: 'Siguiente',
                    icon: VerbumIcons.arrowRight,
                    variant: VButtonVariant.text,
                    compact: true,
                    onPressed: chapter < lastChapter
                        ? () => onOpen(chapter + 1)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
