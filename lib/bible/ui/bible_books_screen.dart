import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/verbum_header_actions.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/bible_book_info.dart';
import '../domain/verse.dart';
import '../services/bible_reading_preferences.dart';
import 'bible_chapters_screen.dart';
import 'bible_verses_screen.dart';
import 'book_covers.dart';
import 'catholic_bible_screen.dart';
import '../../screens/content_sources_screen.dart';
import '../../design_system/design_system.dart';
import '../application/bible_reference.dart';
import '../application/passage_text.dart';

class BibleBooksScreen extends StatefulWidget {
  const BibleBooksScreen({super.key});

  @override
  State<BibleBooksScreen> createState() => _BibleBooksScreenState();
}

class _BibleBooksScreenState extends State<BibleBooksScreen> {
  final _searchController = TextEditingController();
  final _preferences = BibleReadingPreferences();
  bool _loading = true;
  String? _error;
  BibleTestament _testament = BibleTestament.old;
  BibleReadingPosition? _lastPosition;
  List<BibleBookInfo> _recentBooks = const [];
  List<Verse> _searchResults = const [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await BibleDb.instance.init();
      final last = await _preferences.getLastPosition();
      final recentIds = await _preferences.getRecentBookIds();
      if (!mounted) return;
      setState(() {
        _lastPosition = last;
        _recentBooks = recentIds
            .map(bibleBookById)
            .whereType<BibleBookInfo>()
            .toList();
        _loading = false;
      });
    } catch (error) {
      debugPrint('Bible init error: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo preparar la Biblia sin conexión.';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final results = await BibleDb.instance.searchVerses(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  bool _openReference(String raw) {
    final reference = parseBibleReference(raw);
    if (reference == null) return false;
    _openChapter(
      reference.book,
      reference.chapter,
      initialVerse: reference.verse,
    );
    return true;
  }

  void _openBook(BibleBookInfo book) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                BibleChaptersScreen(bookId: book.id, bookName: book.name),
          ),
        )
        .then((_) => _refreshReadingState());
  }

  void _openChapter(BibleBookInfo book, int chapter, {int initialVerse = 1}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BibleVersesScreen(
              bookId: book.id,
              bookName: book.name,
              chapter: chapter,
              initialVerse: initialVerse,
            ),
          ),
        )
        .then((_) => _refreshReadingState());
  }

  Future<void> _refreshReadingState() async {
    final last = await _preferences.getLastPosition();
    final recentIds = await _preferences.getRecentBookIds();
    if (!mounted) return;
    setState(() {
      _lastPosition = last;
      _recentBooks = recentIds
          .map(bibleBookById)
          .whereType<BibleBookInfo>()
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      titleWidget: const SizedBox.shrink(),
      centerTitle: false,
      actions: const [VerbumHeaderActions()],
      showBanner: false,
      showGuestNotice: false,
      body: _loading
          ? const Center(
              child: VEmptyState(
                loading: true,
                title: 'Preparando tu Biblia sin conexión…',
              ),
            )
          : _error != null
          ? Center(
              child: VEmptyState(
                icon: VerbumIcons.bookOpenText,
                title: _error!,
                actionLabel: 'Reintentar',
                onAction: _init,
              ),
            )
          : _buildContent(context),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Libros para empezar, con su foto y una línea que invita.
  static const _starters = [
    ('JHN', 'El amor hecho carne', VerbumPhotos.handsOnBible),
    ('PSA', 'Oración y alabanza', VerbumPhotos.lake),
    ('MAT', 'Las bienaventuranzas', VerbumPhotos.sunrisePrayer),
    ('PRO', 'Sabiduría para el día', VerbumPhotos.journaling),
    ('GEN', 'En el principio', VerbumPhotos.morning),
    ('ROM', 'La fe que justifica', VerbumPhotos.windowReading),
  ];

  static const _gutter = EdgeInsets.symmetric(horizontal: VerbumSpace.gutter);

  Widget _buildContent(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final query = _searchController.text.trim();
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 28),
      children: [
        const Padding(
          padding: _gutter,
          child: VTwoToneTitle('la Palabra', 'Abre', accentFirst: true),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VerbumSpace.gutter,
            6,
            VerbumSpace.gutter,
            16,
          ),
          child: Text(
            'Reina-Valera 1909 · 66 libros · sin conexión',
            style: type.body.copyWith(color: p.inkMuted),
          ),
        ),
        Padding(padding: _gutter, child: _buildSearch(context)),
        if (query.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              16,
              VerbumSpace.gutter,
              0,
            ),
            child: _buildSearchResults(context),
          )
        else ...[
          const SizedBox(height: 16),
          Padding(padding: _gutter, child: _buildHero(context)),
          if (_recentBooks.isNotEmpty) ...[
            _header('Leíste hace poco'),
            _Shelf(books: _recentBooks, coverWidth: 76, onOpen: _openBook),
          ],
          _header('Para empezar'),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(52) + 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: _gutter,
              itemCount: _starters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final (id, caption, photo) = _starters[i];
                final book = bibleBookById(id)!;
                return VPhotoCard(
                  photo: photo,
                  title: book.name,
                  caption: caption,
                  width: 132,
                  onTap: () => _openBook(book),
                );
              },
            ),
          ),
          _header('Todos los libros'),
          Padding(
            padding: _gutter,
            child: VSegmentedControl<BibleTestament>(
              selected: _testament,
              onChanged: (value) => setState(() => _testament = value),
              segments: const [
                VSegment(value: BibleTestament.old, label: 'Antiguo · 39'),
                VSegment(
                  value: BibleTestament.newTestament,
                  label: 'Nuevo · 27',
                ),
              ],
            ),
          ),
          // Un estante de portadas por sección.
          for (final section in booksBySection(_testament).entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VerbumSpace.gutter + 2,
                20,
                VerbumSpace.gutter + 2,
                10,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(section.key, style: type.rubric)),
                  Text(
                    '${section.value.length}',
                    style: type.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            _Shelf(books: section.value, coverWidth: 96, onOpen: _openBook),
          ],
          _header('Ediciones'),
          Padding(
            padding: _gutter,
            child: VListGroup(
              children: [
                VListRow(
                  leading: VerbumIcons.bookOpen,
                  title: 'Estás leyendo Reina-Valera 1909',
                  subtitle: '66 libros · Sin conexión · Edición protestante',
                  trailing: VerbumIcons.info,
                  onTap: () => _push(const ContentSourcesScreen()),
                ),
                VListRow(
                  leading: VerbumIcons.globe,
                  title: 'Consultar la Biblia católica',
                  subtitle:
                      '73 libros · El Libro del Pueblo de Dios · En línea',
                  onTap: () => _push(const CatholicBibleScreen()),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(String title) => VSectionHeader(
    title,
    padding: const EdgeInsets.fromLTRB(
      VerbumSpace.gutter + 2,
      26,
      VerbumSpace.gutter + 2,
      12,
    ),
  );

  /// Tarjeta periwinkle: continuar donde quedaste o, la primera vez,
  /// una invitación a comenzar por Juan.
  Widget _buildHero(BuildContext context) {
    final position = _lastPosition;
    final book = position == null ? null : bibleBookById(position.bookId);
    if (position == null || book == null) {
      final john = bibleBookById('JHN')!;
      return VFeatureCard(
        eyebrow: 'Para comenzar',
        title: 'El Evangelio de Juan',
        body: 'Un buen lugar para conocer a Jesús, capítulo a capítulo.',
        photo: VerbumPhotos.bibleHills,
        onTap: () => _openChapter(john, 1),
        footer: VButton(
          label: 'Empezar a leer',
          icon: VerbumIcons.arrowRight,
          variant: VButtonVariant.inverse,
          compact: true,
          onPressed: () => _openChapter(john, 1),
        ),
      );
    }
    void open() =>
        _openChapter(book, position.chapter, initialVerse: position.verse);
    return VFeatureCard(
      eyebrow: 'Continúa donde quedaste',
      title: '${position.bookName} ${position.chapter}',
      body: 'Versículo ${position.verse} · Reina-Valera 1909',
      photo: VerbumPhotos.bibleHills,
      onTap: open,
      footer: VButton(
        label: 'Seguir leyendo',
        icon: VerbumIcons.bookmarkSimple,
        iconLeading: true,
        variant: VButtonVariant.inverse,
        compact: true,
        onPressed: open,
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,
      onSubmitted: (value) {
        if (!_openReference(value) && value.trim().length >= 2) {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        hintText: 'Busca Juan 3:16, esperanza, paz…',
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: VIcon(
            VerbumIcons.magnifyingGlass,
            size: 20,
            color: p.inkSubtle,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                icon: VIcon(VerbumIcons.close, size: 18, color: p.inkMuted),
              ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_searching) {
      return const VEmptyState(loading: true, title: 'Buscando…');
    }
    if (_searchResults.isEmpty) {
      return const VEmptyState(
        icon: VerbumIcons.magnifyingGlass,
        title: 'No encontramos coincidencias',
        message: 'Prueba otra palabra o escribe una referencia como Juan 3:16.',
      );
    }
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VRubricLabel('${_searchResults.length} resultados'),
        const SizedBox(height: 10),
        for (final verse in _searchResults)
          if (bibleBookById(verse.book) case final book?)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: VSurfaceCard(
                radius: VerbumRadius.tile,
                padding: const EdgeInsets.all(14),
                onTap: () => _openChapter(
                  book,
                  verse.chapter,
                  initialVerse: verse.verse,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${book.name} ${verse.chapter}:${verse.verse}',
                      style: type.citation.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sanitize(verse.text),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: type.scripture.copyWith(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  String _sanitize(String text) => sanitizeVerseText(text);
}

/// Fila horizontal de portadas.
class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.books,
    required this.coverWidth,
    required this.onOpen,
  });

  final List<BibleBookInfo> books;
  final double coverWidth;
  final ValueChanged<BibleBookInfo> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: coverWidth * 1.5 + 12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          0,
          VerbumSpace.gutter,
          12,
        ),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => BibleBookCover(
          book: books[i],
          width: coverWidth,
          onTap: () => onOpen(books[i]),
        ),
      ),
    );
  }
}
