import 'package:flutter/material.dart';

import '../features/sharing/domain/share_content.dart';
import '../models/spiritual_path.dart';
import '../services/read_aloud_service.dart';
import '../services/share_service.dart';
import '../services/spiritual_path_service.dart';
import 'reading_chat_screen.dart';
import 'package:verbum/design_system/design_system.dart';

class SpiritualPathDayScreen extends StatefulWidget {
  final SpiritualPath path;
  final int dayNumber;
  final Future<void> Function(String pathId, int day, int totalDays)?
  completeDay;
  const SpiritualPathDayScreen({
    super.key,
    required this.path,
    required this.dayNumber,
    this.completeDay,
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
            content: Text(
              'La lectura en voz alta no está disponible en este dispositivo.',
            ),
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
    final completeDay = widget.completeDay;
    if (completeDay == null) {
      await _pathService.completeDay(
        widget.path.id,
        widget.dayNumber,
        widget.path.days.length,
      );
    } else {
      await completeDay(
        widget.path.id,
        widget.dayNumber,
        widget.path.days.length,
      );
    }
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
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  const VBackButton(),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          path.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.bodyStrong,
                        ),
                        Text(
                          'DÍA ${widget.dayNumber} DE ${path.days.length}',
                          style: context.type.rubric.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  VIconButton(
                    icon: _speaking ? VerbumIcons.stop : VerbumIcons.headphones,
                    semanticLabel: _speaking
                        ? 'Detener audio'
                        : 'Escuchar el día',
                    variant: VIconButtonVariant.ghost,
                    onPressed: _toggleNarration,
                  ),
                  VIconButton(
                    icon: VerbumIcons.sparkle,
                    semanticLabel: 'Conversar sobre este día',
                    variant: VIconButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReadingChatScreen(
                          title: _day.title,
                          content: '${_day.scripture}\n\n${_day.reflection}',
                          reference: _day.scriptureReference,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _page ? p.gold : p.lineSoft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _ReadingPage(
                    eyebrow: 'Recibe la Palabra',
                    title: _day.title,
                    subtitle: _day.subtitle,
                    body: _day.scripture,
                    footer: _day.scriptureReference,
                    icon: VerbumIcons.bookOpenText,
                    serifBody: true,
                  ),
                  _ReadingPage(
                    eyebrow: 'Medita',
                    title: 'Deja que la Palabra repose',
                    subtitle: 'Lee sin prisa. No tienes que resolver nada.',
                    body: _day.reflection,
                    icon: VerbumIcons.flowerLotus,
                  ),
                  _ReadingPage(
                    eyebrow: 'Habla con Dios',
                    title: 'Tu oración de hoy',
                    subtitle: 'Puedes leerla o hacerla tuya en silencio.',
                    body: _day.prayer,
                    icon: VerbumIcons.handsPraying,
                    serifBody: true,
                  ),
                  _ReadingPage(
                    eyebrow: 'Llévalo a tu vida',
                    title: 'Un paso pequeño y concreto',
                    subtitle: 'La fe también crece en lo cotidiano.',
                    body: _day.practice,
                    icon: VerbumIcons.personSimpleWalk,
                  ),
                ],
              ),
            ),
            VBottomBar(
              child: Row(
                children: [
                  if (_page > 0) ...[
                    VIconButton(
                      icon: VerbumIcons.arrowLeft,
                      semanticLabel: 'Página anterior',
                      size: 50,
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: VButton(
                      label: _page == 3 ? 'Completar este día' : 'Continuar',
                      icon: _page == 3
                          ? VerbumIcons.check
                          : VerbumIcons.arrowRight,
                      expanded: true,
                      loading: _completing,
                      onPressed: _next,
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
  final VerbumIcons icon;
  final bool serifBody;

  const _ReadingPage({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
    this.footer,
    required this.icon,
    this.serifBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final bodyStyle = serifBody
        ? type.scripture.copyWith(fontSize: 19, height: 1.62)
        : type.body.copyWith(fontSize: 16, height: 1.65, color: p.ink);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      children: [
        VIcon(icon, weight: VIconWeight.duotone, size: 34, color: p.gold),
        const SizedBox(height: 16),
        VRubricLabel(eyebrow),
        const SizedBox(height: 6),
        Text(title, style: type.display.copyWith(fontSize: 32, height: 1.1)),
        const SizedBox(height: 8),
        Text(subtitle, style: type.body),
        const SizedBox(height: 24),
        if (serifBody && body.length >= 120)
          VDropCapText(body, style: bodyStyle)
        else
          Text(body, style: bodyStyle),
        if (footer != null) ...[
          const SizedBox(height: 20),
          Container(width: 38, height: 1, color: p.gold),
          const SizedBox(height: 10),
          Text(footer!, style: type.citation),
        ],
      ],
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  final SpiritualPath path;
  final SpiritualPathDay day;
  final VoidCallback onClose;
  const _CompletionDialog({
    required this.path,
    required this.day,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final finished = day.number == path.days.length;
    return AlertDialog(
      icon: VIcon(
        finished ? VerbumIcons.sealCheck : VerbumIcons.sparkle,
        weight: VIconWeight.duotone,
        size: 44,
        color: p.gold,
      ),
      title: Text(
        finished ? 'Has completado el camino' : 'Tu paso de hoy está completo',
        textAlign: TextAlign.center,
        style: context.type.title.copyWith(fontSize: 26),
      ),
      content: Text(
        finished
            ? 'Lo recorrido no termina aquí: llévalo contigo y vuelve cuando lo necesites.'
            : 'No necesitas hacer más. Permite que este momento te acompañe durante el día.',
        textAlign: TextAlign.center,
        style: context.type.body,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        VButton(
          label: 'Compartir',
          variant: VButtonVariant.text,
          compact: true,
          onPressed: () => ShareService.openComposer(
            context,
            ShareContent(
              title: path.title,
              body: day.scripture,
              reference: '${day.scriptureReference} · RV1909',
              sourceLabel: 'RV1909',
              kind: ShareContentKind.verse,
            ),
          ),
        ),
        VButton(
          label: 'Guardar este momento',
          compact: true,
          onPressed: onClose,
        ),
      ],
    );
  }
}
