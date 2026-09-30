import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Encabezado del capítulo: libro en rúbrica, número en serif y ornamento.
class ChapterHeading extends StatelessWidget {
  const ChapterHeading({
    super.key,
    required this.bookName,
    required this.chapter,
    required this.textColor,
  });

  final String bookName;
  final int chapter;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return Semantics(
      header: true,
      label: '$bookName, capítulo $chapter',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            bookName.toUpperCase(),
            textAlign: TextAlign.center,
            style: type.rubric,
          ),
          const SizedBox(height: 6),
          Text(
            'Capítulo $chapter',
            style: type.display.copyWith(color: textColor, fontSize: 38),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1, color: p.gold),
              const SizedBox(width: 10),
              VIcon(
                VerbumIcons.cross,
                weight: VIconWeight.fill,
                size: 13,
                color: p.gold,
              ),
              const SizedBox(width: 10),
              Container(width: 40, height: 1, color: p.gold),
            ],
          ),
        ],
      ),
    );
  }
}
