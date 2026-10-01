import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Encabezado del capítulo, centrado como en un libro: el libro en
/// versalitas, "Capítulo 9" en serif, un ornamento con cruz y, debajo, la
/// versión y el avance.
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
    final type = context.type;
    return Column(
      children: [
        Semantics(
          header: true,
          label: '$bookName, capítulo $chapter',
          excludeSemantics: true,
          child: Column(
            children: [
              Text(
                bookName.toUpperCase(),
                textAlign: TextAlign.center,
                style: type.rubric.copyWith(letterSpacing: 2.4),
              ),
              const SizedBox(height: 4),
              Text(
                'Capítulo $chapter',
                textAlign: TextAlign.center,
                style: VerbumFonts.serif(
                  color: textColor,
                  fontSize: 44,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 44, height: 1.5, color: p.gold),
              const SizedBox(width: 10),
              VIcon(
                VerbumIcons.cross,
                weight: VIconWeight.fill,
                size: 14,
                color: p.gold,
              ),
              const SizedBox(width: 10),
              Container(width: 44, height: 1.5, color: p.gold),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Reina-Valera 1909 · $chapter de $lastChapter',
          textAlign: TextAlign.center,
          style: type.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
