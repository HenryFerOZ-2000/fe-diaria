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
      titleWidget: Text('Biblia', style: context.type.display),
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

  Widget _buildContent(BuildContext context) {
    final query = _searchController.text.trim();
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
          eyebrow: 'La Palabra',
          title: 'Lee, escucha y permanece',
          body: 'Toda la Escritura disponible para acompañarte donde estés.',
          watermark: VerbumIcons.bookOpenText,
          footer: VMetaChip(
            icon: VerbumIcons.checkCircle,
            label: 'RV1909 · Sin conexión',
            color: context.palette.gold,
          ),
        ),
        const SizedBox(height: 14),
        _buildSearch(context),
        if (query.length >= 2) ...[
          const SizedBox(height: 16),
          _buildSearchResults(context),
        ] else ...[
          if (_lastPosition != null) ...[
            const SizedBox(height: 14),
            _buildContinueCard(_lastPosition!),
          ],
          const VSectionHeader(
            'Accesos rápidos',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VTileGrid(
            minTileWidth: 76,
            spacing: 8,
            children: [
              for (final (id, icon) in const [
                ('PSA', VerbumIcons.feather),
                ('PRO', VerbumIcons.lightbulb),
                ('JHN', VerbumIcons.bookOpenText),
                ('MAT', VerbumIcons.cross),
              ])
                VCategoryTile(
                  icon: icon,
                  title: bibleBookById(id)!.name,
                  iconColor: context.palette.gold,
                  onTap: () => _openBook(bibleBookById(id)!),
                ),
            ],
          ),
          if (_recentBooks.isNotEmpty) ...[
            const VSectionHeader(
              'Recientes',
              padding: EdgeInsets.fromLTRB(2, 22, 2, 10),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recentBooks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final book = _recentBooks[index];
                  return ActionChip(
                    avatar: VIcon(VerbumIcons.clock, size: 15),
                    label: Text(book.name),
                    onPressed: () => _openBook(book),
                  );
                },
              ),
            ),
          ],
          const VSectionHeader(
            'Todos los libros',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VSegmentedControl<BibleTestament>(
            selected: _testament,
            onChanged: (value) => setState(() => _testament = value),
            segments: const [
              VSegment(value: BibleTestament.old, label: 'Antiguo · 39'),
              VSegment(value: BibleTestament.newTestament, label: 'Nuevo · 27'),
            ],
          ),
          const SizedBox(height: 14),
          for (final section in booksBySection(_testament).entries) ...[
            VListGroup(
              title: section.key,
              children: [
                for (final book in section.value)
                  VListRow(title: book.name, onTap: () => _openBook(book)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const VSectionHeader(
            'Ediciones',
            padding: EdgeInsets.fromLTRB(2, 14, 2, 10),
          ),
          VListGroup(
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
                subtitle: '73 libros · El Libro del Pueblo de Dios · En línea',
                onTap: () => _push(const CatholicBibleScreen()),
              ),
            ],
          ),
        ],
      ],
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

  Widget _buildContinueCard(BibleReadingPosition position) {
    final book = bibleBookById(position.bookId);
    if (book == null) return const SizedBox.shrink();
    return VActionTile(
      tone: VSurfaceTone.accent,
      icon: VerbumIcons.bookmarkSimple,
      overline: 'Continuar leyendo',
      title: '${position.bookName} ${position.chapter}:${position.verse}',
      iconColor: context.palette.accent,
      onTap: () =>
          _openChapter(book, position.chapter, initialVerse: position.verse),
    );
  }
}
