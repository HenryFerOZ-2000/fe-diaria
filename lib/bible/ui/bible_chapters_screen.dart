import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/bible_book_info.dart';
import '../services/bible_reading_preferences.dart';
import 'bible_verses_screen.dart';
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
    return AppScaffold(
      titleWidget: Text(
        widget.bookName,
        style: context.type.heading.copyWith(fontSize: 24),
      ),
      centerTitle: false,
      showBanner: false,
      showGuestNotice: false,
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
          return _buildContent(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<int> chapters) {
    final metadata = bibleBookById(widget.bookId);
    final lastHere = _lastPosition?.bookId == widget.bookId
        ? _lastPosition
        : null;
    final count = chapters.length;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        VerbumSpace.gutter,
        4,
        VerbumSpace.gutter,
        28,
      ),
      children: [
        VFeatureCard(
          eyebrow: metadata?.section ?? 'Libro bíblico',
          title: widget.bookName,
          body:
              '$count ${count == 1 ? 'capítulo' : 'capítulos'} · Reina-Valera 1909',
          watermark: VerbumIcons.books,
          footer: lastHere == null
              ? null
              : VButton(
                  label: 'Continuar capítulo ${lastHere.chapter}',
                  icon: VerbumIcons.bookmarkSimple,
                  iconLeading: true,
                  variant: VButtonVariant.inverse,
                  compact: true,
                  onPressed: () => _openChapter(
                    lastHere.chapter,
                    initialVerse: lastHere.verse,
                  ),
                ),
        ),
        const VSectionHeader(
          'Elige un capítulo',
          padding: EdgeInsets.fromLTRB(2, 24, 2, 12),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 520 ? 7 : 5;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
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
