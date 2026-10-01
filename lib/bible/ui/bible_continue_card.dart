import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../domain/bible_book_info.dart';
import '../services/bible_reading_preferences.dart';
import 'bible_verses_screen.dart';
import 'book_covers.dart';

/// "Continúa leyendo": el último capítulo abierto, con la portada de su
/// libro. No aparece si aún no se ha leído nada.
class BibleContinueCard extends StatefulWidget {
  const BibleContinueCard({super.key});

  @override
  State<BibleContinueCard> createState() => _BibleContinueCardState();
}

class _BibleContinueCardState extends State<BibleContinueCard> {
  final _preferences = BibleReadingPreferences();
  late Future<BibleReadingPosition?> _position = _preferences.getLastPosition();

  Future<void> _open(BibleReadingPosition position) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BibleVersesScreen(
          bookId: position.bookId,
          bookName: position.bookName,
          chapter: position.chapter,
          initialVerse: position.verse,
        ),
      ),
    );
    if (mounted) setState(() => _position = _preferences.getLastPosition());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BibleReadingPosition?>(
      future: _position,
      builder: (context, snapshot) {
        final position = snapshot.data;
        final book = position == null ? null : bibleBookById(position.bookId);
        if (position == null || book == null) return const SizedBox.shrink();
        final p = context.palette;
        final type = context.type;
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: VSurfaceCard(
            onTap: () => _open(position),
            radius: VerbumRadius.card,
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            semanticLabel:
                'Continuar leyendo ${position.bookName} ${position.chapter}, '
                'versículo ${position.verse}',
            child: Row(
              children: [
                ExcludeSemantics(
                  child: BibleBookCover(
                    book: book,
                    width: 44,
                    onTap: () => _open(position),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biblia · versículo ${position.verse}',
                        style: type.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${position.bookName} ${position.chapter}',
                        style: type.heading.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                VIcon(VerbumIcons.caretRight, size: 18, color: p.inkSubtle),
              ],
            ),
          ),
        );
      },
    );
  }
}
