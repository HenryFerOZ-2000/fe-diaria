import 'package:flutter/material.dart';
import '../../widgets/source_link.dart';
import '../domain/bible_book_info.dart';
import '../domain/catholic_bible_catalog.dart';

class CatholicBibleScreen extends StatefulWidget {
  const CatholicBibleScreen({super.key});

  @override
  State<CatholicBibleScreen> createState() => _CatholicBibleScreenState();
}

class _CatholicBibleScreenState extends State<CatholicBibleScreen> {
  String _query = '';

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(title: const Text('Biblia católica')),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'El Libro del Pueblo de Dios',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Traducción argentina · 1990\nLectura en línea en la Santa Sede. Cada libro se abre en tu navegador; requiere conexión. Tus marcas de RV1909 permanecen en Verbum.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar un libro',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) =>
                              setState(() => _query = _normalize(value.trim())),
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Antiguo · 46 libros'),
                      Tab(text: 'Nuevo · 27 libros'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _books(context, BibleTestament.old),
              _books(context, BibleTestament.newTestament),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _books(BuildContext context, BibleTestament testament) {
    final books = catholicBibleBooks
        .where(
          (book) =>
              book.testament == testament &&
              _normalize(book.name).contains(_query),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (books.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No hay libros que coincidan en este testamento.'),
          ),
        for (final book in books)
          Card(
            child: ListTile(
              title: Text(book.name),
              subtitle: Text(book.section),
              trailing: const Icon(
                Icons.open_in_new,
                semanticLabel: 'Abrir en la Santa Sede',
              ),
              onTap: () => openSource(
                context,
                '$catholicBibleSource${catholicBookPages[book.id]}',
              ),
            ),
          ),
        if (testament == BibleTestament.old && _query.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Textos que esta edición presenta por separado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final entry in catholicSupplementPages.entries)
            ListTile(
              title: Text(entry.key),
              trailing: const Icon(Icons.open_in_new),
              onTap: () =>
                  openSource(context, '$catholicBibleSource${entry.value}'),
            ),
        ],
      ],
    );
  }
}
