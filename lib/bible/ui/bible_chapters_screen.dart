import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
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

  @override
  void initState() {
    super.initState();
    _chaptersFuture = BibleDb.instance.getChapters(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.bookName,
      body: FutureBuilder<List<int>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se pudieron cargar los capítulos'));
          }
          final chapters = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chap = chapters[index];
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BibleVersesScreen(
                        bookId: widget.bookId,
                        bookName: widget.bookName,
                        chapter: chap,
                      ),
                    ),
                  );
                },
                child: Text(
                  '$chap',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

