import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bible_service.dart';
import '../widgets/app_scaffold.dart';
import '../services/storage_service.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final BibleService _service = BibleService();
  List<String> _books = [];
  String? _selectedBook;
  int _selectedChapter = 1;
  int _chaptersCount = 0;
  List<String> _verses = [];
  Map<String, String> _highlights = {};
  bool _loading = true;
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _service.getBooks();
      if (books.isNotEmpty) {
        final first = books.first;
        setState(() {
          _books = books;
          _selectedBook = first;
        });
        await _loadBookAndChapter(first, 1);
      } else {
        setState(() {
          _books = [];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadBookAndChapter(String book, int chapter) async {
    setState(() {
      _loading = true;
    });
    final chaptersCount = await _service.getChaptersCount(book);
    final verses = await _service.loadChapter(book, chapter);
    await _loadHighlights();
    setState(() {
      _chaptersCount = chaptersCount;
      _selectedChapter = chapter;
      _verses = verses;
      _loading = false;
    });
  }

  Future<void> _loadHighlights() async {
    final map = <String, String>{};
    final keys = _storage.getKeysWithPrefix('hl_');
    for (final key in keys) {
      final val = _storage.getCustomString(key);
      if (val != null && val.isNotEmpty) {
        map[key] = val;
      }
    }
    _highlights = map;
  }

  Future<void> _setHighlight(String book, int chapter, int verse, String? colorName) async {
    final key = 'hl_${book}_${chapter}_$verse';
    if (colorName == null) {
      await _storage.removeCustom(key);
      _highlights.remove(key);
    } else {
      await _storage.setCustomString(key, colorName);
      _highlights[key] = colorName;
    }
    setState(() {});
  }

  Color? _colorFromName(String name) {
    switch (name) {
      case 'yellow':
        return Colors.yellow.withOpacity(0.3);
      case 'green':
        return Colors.lightGreenAccent.withOpacity(0.3);
      case 'blue':
        return Colors.lightBlueAccent.withOpacity(0.3);
      case 'red':
        return Colors.redAccent.withOpacity(0.3);
      default:
        return null;
    }
  }

  void _showHighlightSheet(String key) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Resaltar versículo',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    _highlightOption('Amarillo', Colors.yellow, () => _applyColor(key, 'yellow')),
                    _highlightOption('Verde', Colors.lightGreen, () => _applyColor(key, 'green')),
                    _highlightOption('Azul', Colors.lightBlue, () => _applyColor(key, 'blue')),
                    _highlightOption('Rojo', Colors.redAccent, () => _applyColor(key, 'red')),
                    _highlightOption('Quitar', Colors.grey, () => _applyColor(key, null)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _highlightOption(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  void _applyColor(String key, String? colorName) {
    if (_selectedBook == null) return;
    final parts = key.split('_'); // hl_book_chapter_verse
    if (parts.length < 4) return;
    final book = parts[1];
    final chapter = int.tryParse(parts[2]) ?? _selectedChapter;
    final verse = int.tryParse(parts[3]) ?? 1;
    _setHighlight(book, chapter, verse, colorName);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Biblia',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectors(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildVerses(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectors() {
    final bookItems = _books
        .map(
          (b) => DropdownMenuItem<String>(
            value: b,
            child: Text(
              b,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        )
        .toList();
    final chapterItems = List.generate(_chaptersCount, (i) => i + 1)
        .map(
          (c) => DropdownMenuItem<int>(
            value: c,
            child: Text('Cap. $c'),
          ),
        )
        .toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedBook,
                hint: const Text('Libro'),
                items: bookItems,
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() {
                    _selectedBook = val;
                  });
                  await _loadBookAndChapter(val, 1);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedChapter,
                hint: const Text('Cap.'),
                items: chapterItems,
                onChanged: (val) async {
                  if (val == null || _selectedBook == null) return;
                  await _loadBookAndChapter(_selectedBook!, val);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerses() {
    if (_verses.isEmpty) {
      return Center(
        child: Text(
          'Sin versículos disponibles',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verseNumber = index + 1;
        final key = 'hl_${_selectedBook}_${_selectedChapter}_$verseNumber';
        final colorName = _highlights[key];
        final highlightColor = colorName != null ? _colorFromName(colorName) : null;

        return GestureDetector(
          onLongPress: () => _showHighlightSheet(key),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: highlightColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$verseNumber ',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: _verses[index],
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

