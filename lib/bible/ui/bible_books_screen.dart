import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_scaffold.dart';
import '../data/bible_db.dart';
import 'bible_chapters_screen.dart';

class BibleBooksScreen extends StatefulWidget {
  const BibleBooksScreen({super.key});

  @override
  State<BibleBooksScreen> createState() => _BibleBooksScreenState();
}

class _BibleBooksScreenState extends State<BibleBooksScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await BibleDb.instance.init();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'No se pudo preparar la Biblia offline. Intenta de nuevo.';
      });
      // Log en consola para diagnóstico
      // ignore: avoid_print
      print('Error al copiar DB RV1909: $e');
    }
  }

  static const List<Map<String, String>> _books = [
    {'id': 'GEN', 'name': 'Génesis'},
    {'id': 'EXO', 'name': 'Éxodo'},
    {'id': 'LEV', 'name': 'Levítico'},
    {'id': 'NUM', 'name': 'Números'},
    {'id': 'DEU', 'name': 'Deuteronomio'},
    {'id': 'JOS', 'name': 'Josué'},
    {'id': 'JDG', 'name': 'Jueces'},
    {'id': 'RUT', 'name': 'Rut'},
    {'id': '1SA', 'name': '1 Samuel'},
    {'id': '2SA', 'name': '2 Samuel'},
    {'id': '1KI', 'name': '1 Reyes'},
    {'id': '2KI', 'name': '2 Reyes'},
    {'id': '1CH', 'name': '1 Crónicas'},
    {'id': '2CH', 'name': '2 Crónicas'},
    {'id': 'EZR', 'name': 'Esdras'},
    {'id': 'NEH', 'name': 'Nehemías'},
    {'id': 'EST', 'name': 'Ester'},
    {'id': 'JOB', 'name': 'Job'},
    {'id': 'PSA', 'name': 'Salmos'},
    {'id': 'PRO', 'name': 'Proverbios'},
    {'id': 'ECC', 'name': 'Eclesiastés'},
    {'id': 'SNG', 'name': 'Cantares'},
    {'id': 'ISA', 'name': 'Isaías'},
    {'id': 'JER', 'name': 'Jeremías'},
    {'id': 'LAM', 'name': 'Lamentaciones'},
    {'id': 'EZK', 'name': 'Ezequiel'},
    {'id': 'DAN', 'name': 'Daniel'},
    {'id': 'HOS', 'name': 'Oseas'},
    {'id': 'JOL', 'name': 'Joel'},
    {'id': 'AMO', 'name': 'Amós'},
    {'id': 'OBA', 'name': 'Abdías'},
    {'id': 'JON', 'name': 'Jonás'},
    {'id': 'MIC', 'name': 'Miqueas'},
    {'id': 'NAM', 'name': 'Nahúm'},
    {'id': 'HAB', 'name': 'Habacuc'},
    {'id': 'ZEP', 'name': 'Sofonías'},
    {'id': 'HAG', 'name': 'Hageo'},
    {'id': 'ZEC', 'name': 'Zacarías'},
    {'id': 'MAL', 'name': 'Malaquías'},
    {'id': 'MAT', 'name': 'Mateo'},
    {'id': 'MRK', 'name': 'Marcos'},
    {'id': 'LUK', 'name': 'Lucas'},
    {'id': 'JHN', 'name': 'Juan'},
    {'id': 'ACT', 'name': 'Hechos'},
    {'id': 'ROM', 'name': 'Romanos'},
    {'id': '1CO', 'name': '1 Corintios'},
    {'id': '2CO', 'name': '2 Corintios'},
    {'id': 'GAL', 'name': 'Gálatas'},
    {'id': 'EPH', 'name': 'Efesios'},
    {'id': 'PHP', 'name': 'Filipenses'},
    {'id': 'COL', 'name': 'Colosenses'},
    {'id': '1TH', 'name': '1 Tesalonicenses'},
    {'id': '2TH', 'name': '2 Tesalonicenses'},
    {'id': '1TI', 'name': '1 Timoteo'},
    {'id': '2TI', 'name': '2 Timoteo'},
    {'id': 'TIT', 'name': 'Tito'},
    {'id': 'PHM', 'name': 'Filemón'},
    {'id': 'HEB', 'name': 'Hebreos'},
    {'id': 'JAS', 'name': 'Santiago'},
    {'id': '1PE', 'name': '1 Pedro'},
    {'id': '2PE', 'name': '2 Pedro'},
    {'id': '1JN', 'name': '1 Juan'},
    {'id': '2JN', 'name': '2 Juan'},
    {'id': '3JN', 'name': '3 Juan'},
    {'id': 'JUD', 'name': 'Judas'},
    {'id': 'REV', 'name': 'Apocalipsis'},
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Biblia RV1909 (offline)',
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Preparando Biblia offline...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _initDb,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(
                          book['name']!,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          book['id']!,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BibleChaptersScreen(
                                bookId: book['id']!,
                                bookName: book['name']!,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

