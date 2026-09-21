import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp('[áàä]'), 'a')
        .replaceAll(RegExp('[éèë]'), 'e')
        .replaceAll(RegExp('[íìï]'), 'i')
        .replaceAll(RegExp('[óòö]'), 'o')
        .replaceAll(RegExp('[úùü]'), 'u');
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
    final match = RegExp(r'^(.+?)\s+(\d+)(?::(\d+))?$').firstMatch(raw.trim());
    if (match == null) return false;
    final requestedName = _normalize(match.group(1)!);
    BibleBookInfo? book;
    for (final candidate in bibleBooks) {
      if (_normalize(candidate.name) == requestedName) {
        book = candidate;
        break;
      }
    }
    if (book == null) return false;
    final chapter = int.tryParse(match.group(2)!) ?? 1;
    final verse = int.tryParse(match.group(3) ?? '1') ?? 1;
    _openChapter(book, chapter, initialVerse: verse);
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
      titleWidget: Text(
        'Biblia',
        style: GoogleFonts.playfairDisplay(
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: false,
      actions: const [VerbumHeaderActions()],
      showBanner: false,
      showGuestNotice: false,
      body: _loading
          ? const _BibleLoadingState()
          : _error != null
          ? _BibleErrorState(message: _error!, onRetry: _init)
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final query = _searchController.text.trim();
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _buildHero(context),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Estás leyendo Reina-Valera 1909'),
                subtitle: const Text(
                  '66 libros · Sin conexión · Edición protestante',
                ),
                trailing: const Icon(Icons.info_outline),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContentSourcesScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Consultar la Biblia católica'),
                subtitle: const Text(
                  '73 libros · El Libro del Pueblo de Dios · En línea',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CatholicBibleScreen(),
                  ),
                ),
              ),
            ],
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
            _buildContinueCard(context, _lastPosition!),
          ],
          const SizedBox(height: 22),
          _sectionTitle(context, 'ACCESOS RÁPIDOS', 'Vuelve a lo esencial'),
          const SizedBox(height: 10),
          _buildQuickAccess(context),
          if (_recentBooks.isNotEmpty) ...[
            const SizedBox(height: 22),
            _sectionTitle(context, 'RECIENTES', 'Tus últimos libros'),
            const SizedBox(height: 10),
            _buildRecentBooks(context),
          ],
          const SizedBox(height: 24),
          _sectionTitle(context, 'TODOS LOS LIBROS', 'Explora la Escritura'),
          const SizedBox(height: 11),
          _buildTestamentSelector(context),
          const SizedBox(height: 15),
          ..._buildBookSections(context),
        ],
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 23, 22, 21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241D33), Color(0xFF493759), Color(0xFF76523F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF35243F).withValues(alpha: .24),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -30,
            child: Icon(
              Icons.menu_book_rounded,
              size: 132,
              color: Colors.white.withValues(alpha: .05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'LA PALABRA',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEBCB91),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.55,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .12),
                      ),
                    ),
                    child: Text(
                      'RV1909 · SIN CONEXIÓN',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                'Lee, escucha y\npermanece',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 31,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Toda la Escritura disponible para acompañarte donde estés.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: .70),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: .14)),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_searchResults.isEmpty) {
      return _messageSurface(
        context,
        icon: Icons.search_off_rounded,
        title: 'No encontramos coincidencias',
        text: 'Prueba otra palabra o escribe una referencia como Juan 3:16.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_searchResults.length} RESULTADOS',
          style: GoogleFonts.inter(
            color: scheme.secondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 9),
        ..._searchResults.map((verse) {
          final book = bibleBookById(verse.book);
          if (book == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openChapter(
                  book,
                  verse.chapter,
                  initialVerse: verse.verse,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${book.name} ${verse.chapter}:${verse.verse}',
                        style: GoogleFonts.inter(
                          color: scheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _sanitize(verse.text),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lora(
                          color: scheme.onSurface,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _sanitize(String text) => text
      .replaceAll(RegExp(r'strong="[^"]+"'), '')
      .replaceAll(RegExp(r"strong='[^']+'"), '')
      .replaceAll(RegExp(r'\\w\*?'), '')
      .replaceAll('|', ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  Widget _buildContinueCard(
    BuildContext context,
    BibleReadingPosition position,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final book = bibleBookById(position.bookId);
    if (book == null) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () =>
            _openChapter(book, position.chapter, initialVerse: position.verse),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .085),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.primary.withValues(alpha: .14)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.bookmark_rounded, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTINUAR LEYENDO',
                      style: GoogleFonts.inter(
                        color: scheme.primary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${position.bookName} ${position.chapter}:${position.verse}',
                      style: GoogleFonts.playfairDisplay(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    const ids = ['PSA', 'PRO', 'JHN', 'MAT'];
    return Row(
      children: ids.map((id) {
        final book = bibleBookById(id)!;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: id == ids.last ? 0 : 7),
            child: _QuickBook(book: book, onTap: () => _openBook(book)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentBooks(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentBooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final book = _recentBooks[index];
          return ActionChip(
            avatar: const Icon(Icons.history_rounded, size: 16),
            label: Text(book.name),
            onPressed: () => _openBook(book),
          );
        },
      ),
    );
  }

  Widget _buildTestamentSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .52),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TestamentOption(
            label: 'Antiguo · 39 libros',
            selected: _testament == BibleTestament.old,
            onTap: () => setState(() => _testament = BibleTestament.old),
          ),
          _TestamentOption(
            label: 'Nuevo · 27 libros',
            selected: _testament == BibleTestament.newTestament,
            onTap: () =>
                setState(() => _testament = BibleTestament.newTestament),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBookSections(BuildContext context) {
    final filtered = bibleBooks.where((book) => book.testament == _testament);
    final sections = <String, List<BibleBookInfo>>{};
    for (final book in filtered) {
      sections.putIfAbsent(book.section, () => []).add(book);
    }
    return sections.entries
        .map(
          (entry) => _BookSection(
            title: entry.key,
            books: entry.value,
            onBookTap: _openBook,
          ),
        )
        .toList();
  }

  Widget _sectionTitle(BuildContext context, String eyebrow, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: GoogleFonts.inter(
            color: scheme.secondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: scheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _messageSurface(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: .14)),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: 31),
          const SizedBox(height: 9),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBook extends StatelessWidget {
  final BibleBookInfo book;
  final VoidCallback onTap;

  const _QuickBook({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: scheme.outline.withValues(alpha: .13)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                color: scheme.primary,
                size: 20,
              ),
              const SizedBox(height: 7),
              Text(
                book.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: scheme.onSurface,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestamentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TestamentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookSection extends StatelessWidget {
  final String title;
  final List<BibleBookInfo> books;
  final ValueChanged<BibleBookInfo> onBookTap;

  const _BookSection({
    required this.title,
    required this.books,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: .13)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                color: scheme.secondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...books.asMap().entries.map((entry) {
            final book = entry.value;
            return Column(
              children: [
                if (entry.key > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: scheme.outline.withValues(alpha: .09),
                  ),
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    book.name,
                    style: GoogleFonts.inter(
                      color: scheme.onSurface,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Abrir capítulos',
                    style: GoogleFonts.inter(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () => onBookTap(book),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BibleLoadingState extends StatelessWidget {
  const _BibleLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Preparando tu Biblia sin conexión…'),
        ],
      ),
    );
  }
}

class _BibleErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BibleErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
