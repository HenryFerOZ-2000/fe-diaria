import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../application/passage_text.dart';
import '../domain/chapter_summary.dart';

/// Un capítulo en la lista del libro: número, cuántos versículos tiene y
/// cómo empieza. El último leído va en mantequilla.
class ChapterRow extends StatelessWidget {
  const ChapterRow({
    super.key,
    required this.summary,
    required this.onTap,
    this.lastVerse,
  });

  final ChapterSummary summary;
  final VoidCallback onTap;

  /// Versículo donde te quedaste, si este es el último capítulo leído.
  final int? lastVerse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final current = lastVerse != null;
    final opening = softenOpeningCaps(sanitizeVerseText(summary.opening));
    final meta = current
        ? 'Aquí te quedaste · v. $lastVerse'
        : '${summary.verseCount} versículos';

    return Semantics(
      button: true,
      label: 'Capítulo ${summary.chapter}, $meta. $opening',
      excludeSemantics: true,
      child: VSurfaceCard(
        onTap: onTap,
        radius: VerbumRadius.tile,
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: current ? p.butter : p.surfaceMuted,
                borderRadius: BorderRadius.circular(VerbumRadius.control),
              ),
              child: Text(
                '${summary.chapter}',
                style: type.title.copyWith(
                  fontSize: summary.chapter >= 100 ? 18 : 22,
                  color: current ? p.onButter : p.rubric,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Capítulo ${summary.chapter}',
                        style: type.bodyStrong,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.caption.copyWith(
                            color: current ? p.rubric : null,
                            fontWeight: current ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opening,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.scripture.copyWith(
                      fontSize: 15.5,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      color: p.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
