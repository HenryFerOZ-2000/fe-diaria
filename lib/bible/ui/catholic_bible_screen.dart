import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/source_link.dart';
import '../application/bible_reference.dart';
import '../domain/bible_book_info.dart';
import '../domain/catholic_bible_catalog.dart';

/// Índice de "El Libro del Pueblo de Dios": cada libro se abre en el sitio de
/// la Santa Sede.
class CatholicBibleScreen extends StatefulWidget {
  const CatholicBibleScreen({super.key});

  @override
  State<CatholicBibleScreen> createState() => _CatholicBibleScreenState();
}

class _CatholicBibleScreenState extends State<CatholicBibleScreen> {
  String _query = '';
  BibleTestament _testament = BibleTestament.old;

  void _open(String page) => openSource(context, '$catholicBibleSource$page');

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final p = context.palette;
    final books = catholicBibleBooks
        .where(
          (book) =>
              book.testament == _testament &&
              normalizeBookName(book.name).contains(_query),
        )
        .toList();

    return AppScaffold(
      titleWidget: Text('Biblia católica', style: type.heading),
      centerTitle: false,
      showBanner: false,
      showGuestNotice: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          4,
          VerbumSpace.gutter,
          28,
        ),
        children: [
          Text('El Libro del Pueblo de Dios', style: type.title),
          const SizedBox(height: 6),
          Text(
            'Traducción argentina · 1990. Lectura en línea en la Santa Sede: '
            'cada libro se abre en tu navegador y requiere conexión. Tus '
            'marcas de RV1909 permanecen en Verbum.',
            style: type.body,
          ),
          const SizedBox(height: 14),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar un libro',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: VIcon(
                  VerbumIcons.magnifyingGlass,
                  size: 20,
                  color: p.inkSubtle,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
            ),
            onChanged: (value) =>
                setState(() => _query = normalizeBookName(value)),
          ),
          const SizedBox(height: 14),
          VSegmentedControl<BibleTestament>(
            selected: _testament,
            onChanged: (value) => setState(() => _testament = value),
            segments: const [
              VSegment(value: BibleTestament.old, label: 'Antiguo · 46'),
              VSegment(value: BibleTestament.newTestament, label: 'Nuevo · 27'),
            ],
          ),
          const SizedBox(height: 14),
          if (books.isEmpty)
            const VEmptyState(
              icon: VerbumIcons.magnifyingGlass,
              title: 'No hay libros que coincidan en este testamento.',
            )
          else
            VListGroup(
              children: [
                for (final book in books)
                  VListRow(
                    title: book.name,
                    subtitle: book.section,
                    trailing: VerbumIcons.arrowSquareOut,
                    semanticHint: 'Abrir en la Santa Sede',
                    onTap: () => _open(catholicBookPages[book.id]!),
                  ),
              ],
            ),
          if (_testament == BibleTestament.old && _query.isEmpty) ...[
            const SizedBox(height: 14),
            VListGroup(
              title: 'Textos que esta edición presenta por separado',
              children: [
                for (final entry in catholicSupplementPages.entries)
                  VListRow(
                    title: entry.key,
                    trailing: VerbumIcons.arrowSquareOut,
                    semanticHint: 'Abrir en la Santa Sede',
                    onTap: () => _open(entry.value),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
