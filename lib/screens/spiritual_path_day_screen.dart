import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/spiritual_path.dart';
import '../services/read_aloud_service.dart';
import '../services/share_service.dart';
import '../services/spiritual_path_service.dart';
import 'reading_chat_screen.dart';

class SpiritualPathDayScreen extends StatefulWidget {
  final SpiritualPath path;
  final int dayNumber;
  const SpiritualPathDayScreen({
    super.key,
    required this.path,
    required this.dayNumber,
  });

  @override
  State<SpiritualPathDayScreen> createState() => _SpiritualPathDayScreenState();
}

class _SpiritualPathDayScreenState extends State<SpiritualPathDayScreen> {
  final _pageController = PageController();
  final _pathService = SpiritualPathService();
  final _readAloud = ReadAloudService();
  int _page = 0;
  bool _speaking = false;
  bool _completing = false;

  SpiritualPathDay get _day => widget.path.days[widget.dayNumber - 1];

  @override
  void dispose() {
    _pageController.dispose();
    _readAloud.stop();
    super.dispose();
  }

  Future<void> _toggleNarration() async {
    if (_speaking) {
      await _readAloud.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      await _readAloud.speak(_day.narration);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La lectura en voz alta no está disponible en este dispositivo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _next() async {
    if (_page < 3) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (_completing) return;
    setState(() => _completing = true);
    await _pathService.completeDay(
      widget.path.id,
      widget.dayNumber,
      widget.path.days.length,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CompletionDialog(
        path: widget.path,
        day: _day,
        onClose: () {
          Navigator.pop(dialogContext);
          Navigator.pop(context, true);
        },
      ),
    );
    if (mounted) setState(() => _completing = false);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF241C38),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          path.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'DÍA ${widget.dayNumber} DE ${path.days.length}',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 8,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _speaking ? 'Detener audio' : 'Escuchar el día',
                    onPressed: _toggleNarration,
                    icon: Icon(
                      _speaking ? Icons.stop_circle_outlined : Icons.headphones_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Conversar sobre este día',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReadingChatScreen(
                          title: _day.title,
                          content: '${_day.scripture}\n\n${_day.reflection}',
                          reference: _day.scriptureReference,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.auto_awesome_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 3,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: index <= _page
                            ? const Color(0xFFE6C77D)
                            : Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _ReadingPage(
                    eyebrow: 'RECIBE LA PALABRA',
                    title: _day.title,
                    subtitle: _day.subtitle,
                    body: _day.scripture,
                    footer: _day.scriptureReference,
                    icon: Icons.menu_book_rounded,
                    accent: path.accent,
                    serifBody: true,
                  ),
                  _ReadingPage(
                    eyebrow: 'MEDITA',
                    title: 'Deja que la Palabra repose',
                    subtitle: 'Lee sin prisa. No tienes que resolver nada.',
                    body: _day.reflection,
                    icon: Icons.auto_awesome_outlined,
                    accent: path.accent,
                  ),
                  _ReadingPage(
                    eyebrow: 'HABLA CON DIOS',
                    title: 'Tu oración de hoy',
                    subtitle: 'Puedes leerla o hacerla tuya en silencio.',
                    body: _day.prayer,
                    icon: Icons.favorite_outline_rounded,
                    accent: path.accent,
                    serifBody: true,
                  ),
                  _ReadingPage(
                    eyebrow: 'LLÉVALO A TU VIDA',
                    title: 'Un paso pequeño y concreto',
                    subtitle: 'La fe también crece en lo cotidiano.',
                    body: _day.practice,
                    icon: Icons.directions_walk_rounded,
                    accent: path.accent,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    IconButton.filledTonal(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .12),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _completing ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF7F1E7),
                        foregroundColor: const Color(0xFF302443),
                      ),
                      icon: _completing
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_page == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                      label: Text(_page == 3 ? 'Completar este día' : 'Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingPage extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String body;
  final String? footer;
  final IconData icon;
  final Color accent;
  final bool serifBody;

  const _ReadingPage({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
    this.footer,
    required this.icon,
    required this.accent,
    this.serifBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 500),
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFDF7), Color(0xFFF2EADC)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 24),
            Text(
              eyebrow,
              style: GoogleFonts.inter(
                color: accent,
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFF282034),
                fontSize: 27,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: const Color(0xFF716879),
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 27),
            Text(
              body,
              style: serifBody
                  ? GoogleFonts.merriweather(
                      color: const Color(0xFF30283A),
                      fontSize: 18,
                      height: 1.8,
                    )
                  : GoogleFonts.inter(
                      color: const Color(0xFF30283A),
                      fontSize: 16,
                      height: 1.75,
                    ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 24),
              Container(width: 38, height: 1, color: accent.withValues(alpha: .55)),
              const SizedBox(height: 10),
              Text(
                footer!,
                style: GoogleFonts.inter(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  final SpiritualPath path;
  final SpiritualPathDay day;
  final VoidCallback onClose;
  const _CompletionDialog({required this.path, required this.day, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final finished = day.number == path.days.length;
    return AlertDialog(
      icon: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: path.accent.withValues(alpha: .12),
          shape: BoxShape.circle,
        ),
        child: Icon(finished ? Icons.celebration_rounded : Icons.auto_awesome_rounded, color: path.accent, size: 31),
      ),
      title: Text(
        finished ? 'Has completado el camino' : 'Tu paso de hoy está completo',
        textAlign: TextAlign.center,
        style: GoogleFonts.playfairDisplay(fontSize: 23, fontWeight: FontWeight.w700),
      ),
      content: Text(
        finished
            ? 'Lo recorrido no termina aquí: llévalo contigo y vuelve cuando lo necesites.'
            : 'No necesitas hacer más. Permite que este momento te acompañe durante el día.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 13, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => ShareService.shareAsText(
            text: day.scripture,
            reference: day.scriptureReference,
            title: path.title,
          ),
          child: const Text('Compartir'),
        ),
        FilledButton(onPressed: onClose, child: const Text('Guardar este momento')),
      ],
    );
  }
}
