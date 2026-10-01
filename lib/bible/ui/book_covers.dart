import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../domain/bible_book_info.dart';

/// Color, tinta e icono de portada por sección de la Biblia. Son colores de
/// encuadernación: no cambian con el modo oscuro.
typedef BookCoverStyle = ({
  Color background,
  Color foreground,
  VerbumIcons icon,
});

const _sectionStyles = <String, BookCoverStyle>{
  'Pentateuco': (
    background: Color(0xFF8A8DE6),
    foreground: Color(0xFFFFFFFF),
    icon: VerbumIcons.scroll,
  ),
  'Libros históricos': (
    background: Color(0xFF5D60C4),
    foreground: Color(0xFFFFFFFF),
    icon: VerbumIcons.crown,
  ),
  'Poéticos y sapienciales': (
    background: Color(0xFFF4DF7A),
    foreground: Color(0xFF3A2F05),
    icon: VerbumIcons.feather,
  ),
  'Profetas mayores': (
    background: Color(0xFF3A3C8E),
    foreground: Color(0xFFF4DF7A),
    icon: VerbumIcons.flame,
  ),
  'Profetas menores': (
    background: Color(0xFFC9CBF5),
    foreground: Color(0xFF22245A),
    icon: VerbumIcons.eye,
  ),
  'Evangelios': (
    background: Color(0xFF22245A),
    foreground: Color(0xFFF4DF7A),
    icon: VerbumIcons.cross,
  ),
  'Historia de la Iglesia': (
    background: Color(0xFF6F72D3),
    foreground: Color(0xFFFFFFFF),
    icon: VerbumIcons.bird,
  ),
  'Cartas de Pablo': (
    background: Color(0xFFE9EBF8),
    foreground: Color(0xFF3A3C8E),
    icon: VerbumIcons.envelope,
  ),
  'Cartas generales': (
    background: Color(0xFFFBF2C6),
    foreground: Color(0xFF3A2F05),
    icon: VerbumIcons.quotes,
  ),
  'Profecía': (
    background: Color(0xFF10122A),
    foreground: Color(0xFFF4DF7A),
    icon: VerbumIcons.starFour,
  ),
};

/// Estilo de portada de una sección; secciones desconocidas usan el de
/// los libros históricos.
BookCoverStyle coverStyleFor(String section) =>
    _sectionStyles[section] ?? _sectionStyles['Libros históricos']!;

/// Portada de un libro bíblico.
class BibleBookCover extends StatelessWidget {
  const BibleBookCover({
    super.key,
    required this.book,
    required this.onTap,
    this.width = 96,
  });

  final BibleBookInfo book;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final style = coverStyleFor(book.section);
    return VBookCover(
      title: book.name,
      caption: book.section,
      background: style.background,
      foreground: style.foreground,
      icon: style.icon,
      width: width,
      onTap: onTap,
    );
  }
}
