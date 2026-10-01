import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/bible_book_info.dart';
import '../domain/chapter_summary.dart';
import '../services/bible_reading_preferences.dart';
import 'bible_verses_screen.dart';
import 'book_covers.dart';
import 'chapter_row.dart';
import '../../design_system/design_system.dart';

class BibleChaptersScreen extends StatefulWidget {
  final String bookId;
  final String bookName;

  const BibleChaptersScreen({
    super.key,
    required this.bookId,
    required this.bookName,
  });

  @override
  State<BibleChaptersScreen> createState() => _BibleChaptersScreenState();
}

class _BibleChaptersScreenState extends State<BibleChaptersScreen> {
  late Future<List<ChapterSummary>> _chaptersFuture;
  final _preferences = BibleReadingPreferences();
  BibleReadingPosition? _lastPosition;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = BibleDb.instance.getChapterSummaries(widget.bookId);
    _loadLastPosition();
  }

  Future<void> _loadLastPosition() async {
    final position = await _preferences.getLastPosition();
    if (mounted) setState(() => _lastPosition = position);
  }

  void _openChapter(int chapter, {int initialVerse = 1}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BibleVersesScreen(
              bookId: widget.bookId,
              bookName: widget.bookName,
              chapter: chapter,
              initialVerse: initialVerse,
            ),
          ),
        )
        .then((_) => _loadLastPosition());
  }

  /// Pide un número de capítulo y lo abre; útil en libros largos.
  Future<void> _askChapter(int count) async {
    final chapter = await showDialog<int>(
      context: context,
      builder: (_) => _GoToChapterDialog(count: count),
    );
    if (chapter != null && mounted) _openChapter(chapter);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final book = bibleBookById(widget.bookId);
    final tint = book == null
        ? p.surfaceMuted
        : coverStyleFor(book.section).background;
    return AppScaffold(
      titleWidget: const SizedBox.shrink(),
      centerTitle: false,
      showBanner: false,
      showGuestNotice: false,
      // El fondo toma el color de la portada del libro y se aclara.
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.alphaBlend(tint.withValues(alpha: .28), p.background),
          p.background,
        ],
        stops: const [0, .42],
      ),
      body: FutureBuilder<List<ChapterSummary>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: VEmptyState(loading: true, title: 'Cargando capítulos…'),
            );
          }
          if (snapshot.hasError || snapshot.data?.isEmpty != false) {
            return const Center(
              child: VEmptyState(
                icon: VerbumIcons.bookOpenText,
                title: 'No se pudieron cargar los capítulos.',
              ),
            );
          }
          return _buildContent(context, snapshot.data!, book);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ChapterSummary> chapters,
    BibleBookInfo? book,
  ) {
    final p = context.palette;
    final type = context.type;
    final lastHere = _lastPosition?.bookId == widget.bookId
        ? _lastPosition
        : null;
    final count = chapters.length;
    final section = book?.section ?? 'Libro bíblico';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        VerbumSpace.gutter,
        4,
        VerbumSpace.gutter,
        28,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book != null)
              Transform.rotate(
                angle: -0.05,
                child: BibleBookCover(
                  book: book,
                  width: 112,
                  onTap: () => _openChapter(lastHere?.chapter ?? 1),
                ),
              ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section, style: type.rubric),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(widget.bookName, style: type.display),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sectionBlurb(section),
                    style: type.body.copyWith(color: p.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            VMetaChip(
              icon: VerbumIcons.listBullets,
              label: '$count ${count == 1 ? 'capítulo' : 'capítulos'}',
              color: p.rubric,
            ),
            VMetaChip(label: 'Reina-Valera 1909', color: p.rubric),
          ],
        ),
        const SizedBox(height: 18),
        VButton(
          label: lastHere == null
              ? 'Empezar en el capítulo 1'
              : 'Continuar en el capítulo ${lastHere.chapter}',
          icon: lastHere == null
              ? VerbumIcons.arrowRight
              : VerbumIcons.bookmarkSimple,
          iconLeading: lastHere != null,
          expanded: true,
          onPressed: () => lastHere == null
              ? _openChapter(1)
              : _openChapter(lastHere.chapter, initialVerse: lastHere.verse),
        ),
        VSectionHeader(
          '$count ${count == 1 ? 'capítulo' : 'capítulos'}',
          trailing: count > 1 ? 'Ir al capítulo…' : null,
          onTrailingTap: count > 1 ? () => _askChapter(count) : null,
          padding: const EdgeInsets.fromLTRB(2, 28, 2, 12),
        ),
        for (final summary in chapters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ChapterRow(
              summary: summary,
              lastVerse: lastHere?.chapter == summary.chapter
                  ? lastHere!.verse
                  : null,
              onTap: () => lastHere?.chapter == summary.chapter
                  ? _openChapter(summary.chapter, initialVerse: lastHere!.verse)
                  : _openChapter(summary.chapter),
            ),
          ),
      ],
    );
  }
}

class _GoToChapterDialog extends StatefulWidget {
  const _GoToChapterDialog({required this.count});

  final int count;

  @override
  State<_GoToChapterDialog> createState() => _GoToChapterDialogState();
}

class _GoToChapterDialogState extends State<_GoToChapterDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 1 || value > widget.count) {
      setState(() => _error = 'Escribe un número del 1 al ${widget.count}');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ir al capítulo'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: '1 – ${widget.count}',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Abrir')),
      ],
    );
  }
}
