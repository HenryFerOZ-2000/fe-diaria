import 'package:flutter/material.dart';
import '../bible/ui/bible_books_screen.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  @override
  Widget build(BuildContext context) {
    // Mostrar directamente la Biblia offline (RV1909)
    return const BibleBooksScreen();
  }
}

