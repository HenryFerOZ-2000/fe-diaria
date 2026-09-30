import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/sharing/domain/share_content.dart';
import '../../screens/reading_chat_screen.dart';
import '../../services/share_service.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/verse.dart';
import '../services/bible_reading_preferences.dart';
import '../../services/read_aloud_service.dart';
import '../../design_system/design_system.dart';
import '../application/passage_text.dart';
import '../application/reader_tone.dart';
import 'reader/chapter_heading.dart';
import 'reader/chapter_nav_bar.dart';
import 'reader/reader_colors.dart';
import 'reader/reader_settings_sheet.dart';
import 'reader/verse_tile.dart';

class BibleVersesScreen extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapter;
  final int initialVerse;
  final Future<List<Verse>> Function(String bookId, int chapter)? chapterLoader;
  final Future<List<int>> Function(String bookId)? chaptersLoader;

  const BibleVersesScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    this.initialVerse = 1,
    this.chapterLoader,
    this.chaptersLoader,
  });

  @override
  State<BibleVersesScreen> createState() => _BibleVersesScreenState();
}

class _BibleVersesScreenState extends State<BibleVersesScreen> {
  final _preferences = BibleReadingPreferences();
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  late Future<List<Verse>> _versesFuture;
  List<Verse> _verses = const [];
  Set<int> _selected = {};
  Set<String> _highlights = {};
  double _fontSize = 18;
  double _lineHeight = 1.65;
  ReaderTone _tone = ReaderTone.system;
  int _maxChapter = 1;
  bool _didScrollToInitial = false;
  Timer? _positionDebounce;
  final _readAloud = ReadAloudService();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _versesFuture = _loadChapter();
    _scrollController.addListener(_rememberVisibleVerse);
    _loadReaderPreferences();
  }

  @override
  void dispose() {
    _positionDebounce?.cancel();
    _scrollController.removeListener(_rememberVisibleVerse);
    _scrollController.dispose();
    _readAloud.stop();
    super.dispose();
  }

  Future<void> _toggleReadAloud() async {
    if (_speaking) {
      await _readAloud.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    if (_verses.isEmpty) return;
    final chosen = _selectedVerses.isEmpty ? _verses : _selectedVerses;
    final text = chosen
        .map((verse) => '${verse.verse}. ${_sanitize(verse.text)}')
        .join(' ');
    setState(() => _speaking = true);
    try {
      await _readAloud.speak(
        '${widget.bookName}, capítulo ${widget.chapter}. $text',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo iniciar la lectura en voz alta.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<List<Verse>> _loadChapter() async {
    final results = await Future.wait([
      widget.chapterLoader?.call(widget.bookId, widget.chapter) ??
          BibleDb.instance.getChapter(widget.bookId, widget.chapter),
      widget.chaptersLoader?.call(widget.bookId) ??
          BibleDb.instance.getChapters(widget.bookId),
    ]);
    final verses = results[0] as List<Verse>;
    final chapters = results[1] as List<int>;
    if (verses.isEmpty ||
        !verses.any((verse) => verse.verse == widget.initialVerse)) {
      throw StateError('Referencia no disponible en Reina-Valera 1909.');
    }
    _verses = verses;
    if (chapters.isNotEmpty) _maxChapter = chapters.last;
    await _savePosition(widget.initialVerse);
    return verses;
  }

  Future<void> _loadReaderPreferences() async {
    final values = await Future.wait([
      _preferences.getFontSize(),
      _preferences.getLineHeight(),
      _preferences.getTone(),
      _preferences.getHighlights(),
    ]);
    if (!mounted) return;
    setState(() {
      _fontSize = values[0] as double;
      _lineHeight = values[1] as double;
      _tone = ReaderTone.parse(values[2] as String);
      _highlights = values[3] as Set<String>;
    });
  }

  String _sanitize(String text) => sanitizeVerseText(text);

  Future<void> _savePosition(int verse) {
    return _preferences.savePosition(
      BibleReadingPosition(
        bookId: widget.bookId,
        bookName: widget.bookName,
        chapter: widget.chapter,
        verse: verse,
      ),
    );
  }

  void _rememberVisibleVerse() {
    _positionDebounce?.cancel();
    _positionDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      for (final entry in _verseKeys.entries) {
        final context = entry.value.currentContext;
        if (context == null) continue;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) continue;
        final top = box.localToGlobal(Offset.zero).dy;
        if (top >= 72) {
          _savePosition(entry.key);
          break;
        }
      }
    });
  }

  void _scrollToInitialVerse() {
    if (_didScrollToInitial || widget.initialVerse <= 1) return;
    _didScrollToInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _verseKeys[widget.initialVerse]?.currentContext;
      if (target == null || !mounted) return;
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        alignment: .12,
      );
    });
  }

  void _toggleSelection(int verse) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.add(verse)) _selected.remove(verse);
    });
    if (_selected.isNotEmpty) _savePosition(verse);
  }

  List<Verse> get _selectedVerses => selectedInOrder(_verses, _selected);

  String _selectionText() => passageBody(_selectedVerses);

  String _selectionReference() =>
      passageReference(widget.bookName, widget.chapter, _selectedVerses);

  Future<void> _copySelection() async {
    await Clipboard.setData(
      ClipboardData(
        text:
            '${_selectionReference()} · Reina-Valera 1909\n${_selectionText()}',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pasaje copiado')));
  }

  void _shareSelection() {
    ShareService.openComposer(
      context,
      ShareContent(
        title: '${widget.bookName} ${widget.chapter}',
        body: _selectionText(),
        reference: '${_selectionReference()} · RV1909',
        sourceLabel: 'RV1909',
        kind: ShareContentKind.verse,
      ),
    );
  }

  Future<void> _toggleHighlights() async {
    final keys = _selectedVerses.map(
      (verse) =>
          _preferences.highlightKey(widget.bookId, widget.chapter, verse.verse),
    );
    await _preferences.toggleHighlights(keys);
    final updated = await _preferences.getHighlights();
    if (!mounted) return;
    setState(() {
      _highlights = updated;
      _selected = {};
    });
  }

  void _reflectOnSelection() {
    final text = _selectionText();
    final reference = _selectionReference();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingChatScreen(
          title: 'Reflexiona con Verbum',
          content: text,
          reference: reference,
        ),
      ),
    );
  }

  void _openChapter(int chapter) {
    if (chapter < 1 || chapter > _maxChapter) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BibleVersesScreen(
          bookId: widget.bookId,
          bookName: widget.bookName,
          chapter: chapter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context, _tone);
    return AppScaffold(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.bookName} ${widget.chapter}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.heading,
          ),
          Text(
            'REINA-VALERA 1909',
            style: context.type.rubric.copyWith(
              color: context.palette.gold,
              fontSize: 8.5,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      centerTitle: false,
      showBanner: false,
      showGuestNotice: false,
      backgroundColor: colors.page,
      actions: [
        VIconButton(
          icon: _speaking ? VerbumIcons.stop : VerbumIcons.headphones,
          semanticLabel: _speaking ? 'Detener audio' : 'Escuchar capítulo',
          onPressed: _toggleReadAloud,
          variant: VIconButtonVariant.ghost,
        ),
        VIconButton(
          icon: VerbumIcons.textAa,
          semanticLabel: 'Ajustes de lectura',
          onPressed: _showReaderSettings,
          variant: VIconButtonVariant.ghost,
        ),
        const SizedBox(width: 8),
      ],
      bottomNavigationBar: _selected.isNotEmpty
          ? SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: VActionBar(
                leading: _selected.length == 1
                    ? '1 versículo'
                    : '${_selected.length} versículos',
                onClose: () => setState(() => _selected = {}),
                items: [
                  VActionBarItem(
                    icon: VerbumIcons.pencilSimple,
                    label: 'Resaltar',
                    onPressed: _toggleHighlights,
                  ),
                  VActionBarItem(
                    icon: VerbumIcons.copy,
                    label: 'Copiar',
                    onPressed: _copySelection,
                  ),
                  VActionBarItem(
                    icon: VerbumIcons.shareNetwork,
                    label: 'Compartir',
                    onPressed: _shareSelection,
                  ),
                  VActionBarItem(
                    icon: VerbumIcons.sparkle,
                    label: 'Reflexionar',
                    emphasized: true,
                    onPressed: _reflectOnSelection,
                  ),
                ],
              ),
            )
          : ChapterNavBar(
              chapter: widget.chapter,
              lastChapter: _maxChapter,
              onOpen: _openChapter,
            ),
      body: FutureBuilder<List<Verse>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?.isEmpty != false) {
            return Center(
              child: Text(
                'No se pudo cargar este capítulo.',
                style: context.type.body,
              ),
            );
          }
          _scrollToInitialVerse();
          return _buildReader(context, snapshot.data!, colors);
        },
      ),
    );
  }

  Widget _buildReader(
    BuildContext context,
    List<Verse> verses,
    ReaderColors colors,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      color: colors.page,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                ChapterHeading(
                  bookName: widget.bookName,
                  chapter: widget.chapter,
                  textColor: colors.text,
                ),
                const SizedBox(height: 22),
                for (final verse in verses)
                  KeyedSubtree(
                    key: _verseKeys.putIfAbsent(verse.verse, GlobalKey.new),
                    child: VerseTile(
                      number: verse.verse,
                      text: _sanitize(verse.text),
                      fontSize: _fontSize,
                      lineHeight: _lineHeight,
                      textColor: colors.text,
                      selected: _selected.contains(verse.verse),
                      highlighted: _highlights.contains(
                        _preferences.highlightKey(
                          widget.bookId,
                          widget.chapter,
                          verse.verse,
                        ),
                      ),
                      onTap: () => _toggleSelection(verse.verse),
                    ),
                  ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'FIN DEL CAPÍTULO ${widget.chapter}',
                    style: context.type.rubric.copyWith(
                      color: colors.text.withValues(alpha: .4),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReaderSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ReaderSettingsSheet(
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        tone: _tone,
        onFontSize: (v) => setState(() => _fontSize = v),
        onFontSizeEnd: _preferences.setFontSize,
        onLineHeight: (v) => setState(() => _lineHeight = v),
        onLineHeightEnd: _preferences.setLineHeight,
        onTone: (tone) {
          setState(() => _tone = tone);
          _preferences.setTone(tone.name);
        },
      ),
    );
  }
}
