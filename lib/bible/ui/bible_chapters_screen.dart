import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/bible_book_info.dart';
import '../services/bible_reading_preferences.dart';
import 'bible_verses_screen.dart';

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
        style: GoogleFonts.playfairDisplay(
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
      showBanner: false,
      showGuestNotice: false,
      body: FutureBuilder<List<int>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?.isEmpty != false) {
            return const Center(
              child: Text('No se pudieron cargar los capítulos.'),
            );
          }
          return _buildContent(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<int> chapters) {
    final scheme = Theme.of(context).colorScheme;
    final metadata = bibleBookById(widget.bookId);
    final lastHere = _lastPosition?.bookId == widget.bookId
        ? _lastPosition
        : null;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(21, 22, 21, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF251E34), Color(0xFF4C3958), Color(0xFF74513F)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF392844).withValues(alpha: .22),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -22,
                child: Text(
                  '${chapters.length}',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white.withValues(alpha: .045),
                    fontSize: 112,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (metadata?.section ?? 'LIBRO BÍBLICO').toUpperCase(),
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEBCB91),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.bookName,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${chapters.length} ${chapters.length == 1 ? 'capítulo' : 'capítulos'} · Reina-Valera 1909',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: 11.5,
                    ),
                  ),
                  if (lastHere != null) ...[
                    const SizedBox(height: 17),
                    FilledButton.tonalIcon(
                      onPressed: () => _openChapter(
                        lastHere.chapter,
                        initialVerse: lastHere.verse,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .13),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.bookmark_rounded, size: 17),
                      label: Text(
                        'Continuar capítulo ${lastHere.chapter}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ELIGE UN CAPÍTULO',
          style: GoogleFonts.inter(
            color: scheme.secondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Comienza tu lectura',
          style: GoogleFonts.playfairDisplay(
            color: scheme.onSurface,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 520 ? 6 : 5;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 1,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
              ),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isLast = lastHere?.chapter == chapter;
                return Material(
                  color: isLast
                      ? scheme.primary.withValues(alpha: .12)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _openChapter(chapter),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLast
                              ? scheme.primary.withValues(alpha: .45)
                              : scheme.outline.withValues(alpha: .14),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$chapter',
                            style: GoogleFonts.playfairDisplay(
                              color: isLast ? scheme.primary : scheme.onSurface,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isLast)
                            Positioned(
                              right: 7,
                              top: 6,
                              child: Icon(
                                Icons.bookmark_rounded,
                                size: 11,
                                color: scheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
