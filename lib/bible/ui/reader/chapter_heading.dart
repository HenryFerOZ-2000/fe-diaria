import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Encabezado del capítulo: "Lucas 9" en dos tonos y la versión y el
/// avance del libro como chips.
class ChapterHeading extends StatelessWidget {
  const ChapterHeading({
    super.key,
    required this.bookName,
    required this.chapter,
    required this.lastChapter,
    required this.textColor,
  });

  final String bookName;
  final int chapter;
  final int lastChapter;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: '$bookName, capítulo $chapter',
          excludeSemantics: true,
          child: VTwoToneTitle(
            '$chapter',
            bookName,
            accentFirst: true,
            style: context.type.display.copyWith(color: textColor),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            VMetaChip(label: 'Reina-Valera 1909', color: p.rubric),
            VMetaChip(label: '$chapter de $lastChapter', color: p.rubric),
          ],
        ),
      ],
    );
  }
}
