import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/bible_book_info.dart';
import '../services/bible_reading_preferences.dart';
import 'bible_verses_screen.dart';
import 'book_covers.dart';
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
  late Future<List<int>> _chaptersFuture;
  final _preferences = BibleReadingPreferences();
  BibleReadingPosition? _lastPosition;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = BibleDb.instance.getChapters(widget.bookId);
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
      body: FutureBuilder<List<int>>(
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
    List<int> chapters,
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
          'Capítulos',
          trailing: '$count',
          padding: const EdgeInsets.fromLTRB(2, 28, 2, 12),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 520 ? 7 : 5;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: count,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final current = lastHere?.chapter == chapter;
                return VNumberTile(
                  number: chapter,
                  state: current ? VStepState.current : VStepState.upcoming,
                  semanticLabel: current
                      ? 'Capítulo $chapter, último leído'
                      : 'Capítulo $chapter',
                  onTap: () => _openChapter(chapter),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
