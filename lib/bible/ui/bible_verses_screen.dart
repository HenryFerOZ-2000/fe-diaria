import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import '../domain/verse.dart';

class BibleVersesScreen extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapter;

  const BibleVersesScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapter,
  });

  @override
  State<BibleVersesScreen> createState() => _BibleVersesScreenState();
}

class _BibleVersesScreenState extends State<BibleVersesScreen> {
  late Future<List<Verse>> _versesFuture;

  @override
  void initState() {
    super.initState();
    _versesFuture = BibleDb.instance.getChapter(widget.bookId, widget.chapter);
  }

  String _sanitize(String text) {
    var t = text;
    t = t.replaceAll(RegExp(r'strong="[^"]+"'), '');
    t = t.replaceAll(RegExp(r"strong='[^']+'"), '');
    t = t.replaceAll(RegExp(r'\\w\*'), '');
    t = t.replaceAll(RegExp(r'\\w'), '');
    t = t.replaceAll("|", " ");
    t = t.replaceAll(RegExp(r'\s{2,}'), ' ');
    return t.trim();
  }

  void _shareVerse(Verse verse) {
    final ref = '${widget.bookName} ${verse.chapter}:${verse.verse}';
    Share.share('$ref\n${_sanitize(verse.text)}');
  }

  void _copyVerse(Verse verse) async {
    final ref = '${widget.bookName} ${verse.chapter}:${verse.verse}';
    await Clipboard.setData(ClipboardData(text: '$ref\n${_sanitize(verse.text)}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Versículo copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '${widget.bookName} ${widget.chapter}',
      body: FutureBuilder<List<Verse>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se pudieron cargar los versículos'));
          }
          final verses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final v = verses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    '${v.verse}. ${_sanitize(v.text)}',
                    style: GoogleFonts.inter(height: 1.35),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () => _copyVerse(v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => _shareVerse(v),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

