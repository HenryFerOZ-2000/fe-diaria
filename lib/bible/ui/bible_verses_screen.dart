import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../screens/reading_chat_screen.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/verse.dart';
import '../services/bible_reading_preferences.dart';
import '../../services/read_aloud_service.dart';

class BibleVersesScreen extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapter;
  final int initialVerse;

  const BibleVersesScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    this.initialVerse = 1,
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
  String _tone = 'system';
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
      BibleDb.instance.getChapter(widget.bookId, widget.chapter),
      BibleDb.instance.getChapters(widget.bookId),
    ]);
    final verses = results[0] as List<Verse>;
    final chapters = results[1] as List<int>;
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
      _tone = values[2] as String;
      _highlights = values[3] as Set<String>;
    });
  }

  String _sanitize(String text) => text
      .replaceAll(RegExp(r'strong="[^"]+"'), '')
      .replaceAll(RegExp(r"strong='[^']+'"), '')
      .replaceAll(RegExp(r'\\w\*?'), '')
      .replaceAll('|', ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

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

  List<Verse> get _selectedVerses =>
      _verses.where((verse) => _selected.contains(verse.verse)).toList()
        ..sort((a, b) => a.verse.compareTo(b.verse));

  String _selectionText() {
    final selected = _selectedVerses;
    return selected
        .map((verse) => '${verse.verse}. ${_sanitize(verse.text)}')
        .join('\n');
  }

  String _selectionReference() {
    final selected = _selectedVerses;
    if (selected.isEmpty) return '${widget.bookName} ${widget.chapter}';
    final first = selected.first.verse;
    final last = selected.last.verse;
    return '${widget.bookName} ${widget.chapter}:$first${last == first ? '' : '-$last'}';
  }

  Future<void> _copySelection() async {
    await Clipboard.setData(
      ClipboardData(text: '${_selectionReference()}\n${_selectionText()}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pasaje copiado')));
  }

  void _shareSelection() {
    Share.share(
      '${_selectionReference()}\n${_selectionText()}\n\nCompartido desde Verbum',
      subject: _selectionReference(),
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

  Color _readerBackground(BuildContext context) {
    if (_tone == 'warm') return const Color(0xFFF4EBDD);
    if (_tone == 'night') return const Color(0xFF191621);
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF211D29)
        : const Color(0xFFFFFCF7);
  }

  Color _readerText(BuildContext context) {
    if (_tone == 'warm') return const Color(0xFF332A23);
    if (_tone == 'night') return const Color(0xFFE9E1D6);
    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.bookName} ${widget.chapter}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'REINA-VALERA 1909',
            style: GoogleFonts.inter(
              color: scheme.secondary,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      centerTitle: false,
      showBanner: false,
      showGuestNotice: false,
      actions: [
        IconButton(
          tooltip: _speaking ? 'Detener audio' : 'Escuchar capítulo',
          onPressed: _toggleReadAloud,
          icon: Icon(
            _speaking ? Icons.stop_circle_outlined : Icons.headphones_rounded,
          ),
        ),
        TextButton(
          onPressed: _showReaderSettings,
          child: Text(
            'Aa',
            style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 6),
      ],
      bottomNavigationBar: _selected.isNotEmpty
          ? _buildSelectionBar(context)
          : _buildChapterNav(context),
      body: FutureBuilder<List<Verse>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?.isEmpty != false) {
            return const Center(
              child: Text('No se pudo cargar este capítulo.'),
            );
          }
          _scrollToInitialVerse();
          return _buildReader(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildReader(BuildContext context, List<Verse> verses) {
    final textColor = _readerText(context);
    final background = _readerBackground(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      color: background,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 14, 5, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.chapter}',
                        style: GoogleFonts.playfairDisplay(
                          color: textColor,
                          fontSize: 58,
                          height: .8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'CAPÍTULO',
                          style: GoogleFonts.inter(
                            color: textColor.withValues(alpha: .48),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: .025),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: textColor.withValues(alpha: .075),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: verses.map((verse) {
                      final key = _verseKeys.putIfAbsent(
                        verse.verse,
                        () => GlobalKey(),
                      );
                      final selected = _selected.contains(verse.verse);
                      final highlighted = _highlights.contains(
                        _preferences.highlightKey(
                          widget.bookId,
                          widget.chapter,
                          verse.verse,
                        ),
                      );
                      return Semantics(
                        key: key,
                        selected: selected,
                        label:
                            'Versículo ${verse.verse}. ${_sanitize(verse.text)}',
                        child: InkWell(
                          onTap: () => _toggleSelection(verse.verse),
                          onLongPress: () => _toggleSelection(verse.verse),
                          borderRadius: BorderRadius.circular(11),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(
                                      0xFFB58A45,
                                    ).withValues(alpha: .16)
                                  : highlighted
                                  ? const Color(
                                      0xFFE2B763,
                                    ).withValues(alpha: .20)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${verse.verse}  ',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFB17D34),
                                      fontSize: (_fontSize * .58).clamp(9, 13),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(text: _sanitize(verse.text)),
                                ],
                              ),
                              style: GoogleFonts.lora(
                                color: textColor.withValues(alpha: .94),
                                fontSize: _fontSize,
                                height: _lineHeight,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'FIN DEL CAPÍTULO ${widget.chapter}',
                    style: GoogleFonts.inter(
                      color: textColor.withValues(alpha: .40),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
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

  Widget _buildChapterNav(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 9),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outline.withValues(alpha: .12)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: widget.chapter > 1
                    ? () => _openChapter(widget.chapter - 1)
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Anterior'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.chapter} de $_maxChapter',
                style: GoogleFonts.inter(
                  color: scheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: widget.chapter < _maxChapter
                    ? () => _openChapter(widget.chapter + 1)
                    : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outline.withValues(alpha: .14)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Cancelar selección',
              onPressed: () => setState(() => _selected = {}),
              icon: const Icon(Icons.close_rounded),
            ),
            Text(
              '${_selected.length}',
              style: GoogleFonts.inter(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Resaltar',
              onPressed: _toggleHighlights,
              icon: const Icon(Icons.border_color_outlined),
            ),
            IconButton(
              tooltip: 'Copiar',
              onPressed: _copySelection,
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton(
              tooltip: 'Compartir',
              onPressed: _shareSelection,
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton.filledTonal(
              tooltip: 'Reflexionar',
              onPressed: _reflectOnSelection,
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReaderSettings() async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void update(VoidCallback callback) {
            setState(callback);
            setModalState(() {});
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu espacio de lectura',
                  style: GoogleFonts.playfairDisplay(
                    color: scheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ajusta la página para leer con calma.',
                  style: GoogleFonts.inter(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('A', style: GoogleFonts.lora(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 15,
                        max: 25,
                        divisions: 10,
                        onChanged: (value) => update(() => _fontSize = value),
                        onChangeEnd: _preferences.setFontSize,
                      ),
                    ),
                    Text('A', style: GoogleFonts.lora(fontSize: 24)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.format_line_spacing_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _lineHeight,
                        min: 1.35,
                        max: 1.95,
                        divisions: 4,
                        onChanged: (value) => update(() => _lineHeight = value),
                        onChangeEnd: _preferences.setLineHeight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ToneOption(
                      label: 'Sistema',
                      color: scheme.surface,
                      selected: _tone == 'system',
                      darkLabel:
                          Theme.of(context).brightness == Brightness.dark,
                      onTap: () {
                        update(() => _tone = 'system');
                        _preferences.setTone('system');
                      },
                    ),
                    const SizedBox(width: 9),
                    _ToneOption(
                      label: 'Cálido',
                      color: const Color(0xFFF4EBDD),
                      selected: _tone == 'warm',
                      onTap: () {
                        update(() => _tone = 'warm');
                        _preferences.setTone('warm');
                      },
                    ),
                    const SizedBox(width: 9),
                    _ToneOption(
                      label: 'Noche',
                      color: const Color(0xFF191621),
                      selected: _tone == 'night',
                      darkLabel: true,
                      onTap: () {
                        update(() => _tone = 'night');
                        _preferences.setTone('night');
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ToneOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool darkLabel;
  final VoidCallback onTap;

  const _ToneOption({
    required this.label,
    required this.color,
    required this.selected,
    this.darkLabel = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: .25),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: darkLabel ? Colors.white : const Color(0xFF332A23),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
