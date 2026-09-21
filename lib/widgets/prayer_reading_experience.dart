import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/share_service.dart';
import '../services/read_aloud_service.dart';
import '../faith/content_provenance.dart';

class PrayerReadingExperience extends StatefulWidget {
  final bool loading;
  final ContentProvenance? provenance;
  final String? error;
  final String category;
  final String? title;
  final String? text;
  final String? verseReference;
  final List<String> tags;
  final Color accent;
  final VoidCallback onBack;
  final VoidCallback? onRetry;
  final VoidCallback? onShare;
  final VoidCallback? onComplete;
  final VoidCallback? onNext;
  final bool initiallyCompleted;
  final String primaryActionLabel;
  final String completedActionLabel;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  const PrayerReadingExperience({
    super.key,
    required this.loading,
    this.provenance = ContentProvenance.unverified,
    required this.category,
    required this.accent,
    required this.onBack,
    this.error,
    this.title,
    this.text,
    this.verseReference,
    this.tags = const [],
    this.onRetry,
    this.onShare,
    this.onComplete,
    this.onNext,
    this.initiallyCompleted = false,
    this.primaryActionLabel = 'He terminado mi oración',
    this.completedActionLabel = 'Continuar',
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  @override
  State<PrayerReadingExperience> createState() =>
      _PrayerReadingExperienceState();
}

class _PrayerReadingExperienceState extends State<PrayerReadingExperience> {
  final _scroll = ScrollController();
  double _progress = 0;
  double _fontSize = 18;
  bool _centerText = false;
  bool _completed = false;
  final _readAloud = ReadAloudService();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.initiallyCompleted;
    _scroll.addListener(_updateProgress);
  }

  @override
  void didUpdateWidget(covariant PrayerReadingExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _completed = widget.initiallyCompleted;
      _progress = 0;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  void _updateProgress() {
    if (!_scroll.hasClients) return;
    final extent = _scroll.position.maxScrollExtent;
    final value = extent <= 0 ? 1.0 : (_scroll.offset / extent).clamp(0.0, 1.0);
    if ((value - _progress).abs() > .01) setState(() => _progress = value);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _readAloud.stop();
    super.dispose();
  }

  Future<void> _toggleReadAloud() async {
    if (_speaking) {
      await _readAloud.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    final text = widget.text?.trim() ?? '';
    if (text.isEmpty) return;
    setState(() => _speaking = true);
    try {
      await _readAloud.speak(
        '${widget.title ?? ''}. $text. ${widget.verseReference ?? ''}',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La lectura en voz alta no está disponible.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheet = dark ? const Color(0xFF24202D) : const Color(0xFFFFFCF5);
    final ink = dark ? const Color(0xFFF2EDF5) : const Color(0xFF292330);

    return Scaffold(
      backgroundColor: const Color(0xFF15121D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF15121D),
                  Color.alphaBlend(
                    widget.accent.withValues(alpha: .24),
                    const Color(0xFF211A2C),
                  ),
                  const Color(0xFF17131E),
                ],
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: -70,
            child: _Glow(color: widget.accent, size: 300),
          ),
          Positioned(
            left: -100,
            bottom: 40,
            child: _Glow(color: const Color(0xFFB58A45), size: 260),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                ClipRRect(
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 2,
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    color: widget.accent,
                  ),
                ),
                Expanded(
                  child: widget.loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: widget.accent,
                          ),
                        )
                      : widget.error != null
                      ? _errorState()
                      : _reading(sheet, ink),
                ),
                if (!widget.loading &&
                    widget.error == null &&
                    widget.text != null)
                  _bottomAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final showCategory = constraints.maxWidth >= 360 || textScale <= 1.3;
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              if (showCategory)
                Expanded(
                  child: Text(
                    widget.category.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.7,
                    ),
                  ),
                )
              else
                const Spacer(),
              IconButton(
                onPressed: _toggleReadAloud,
                tooltip: _speaking ? 'Detener audio' : 'Escuchar',
                icon: Icon(
                  _speaking
                      ? Icons.stop_circle_outlined
                      : Icons.headphones_rounded,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _showReadingSettings,
                tooltip: 'Ajustes de lectura',
                icon: const Icon(
                  Icons.text_fields_rounded,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: widget.onShare,
                tooltip: 'Compartir',
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reading(Color sheet, Color ink) {
    final paragraphs = (widget.text ?? '')
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(.04, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        key: ValueKey(widget.text),
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
          decoration: BoxDecoration(
            color: sheet,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: widget.accent.withValues(alpha: .18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .28),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.title ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: ink,
                  fontSize: 29,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_estimatedMinutes(widget.text ?? '')} MIN DE LECTURA',
                style: GoogleFonts.inter(
                  color: widget.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 26),
              ...paragraphs.map(
                (paragraph) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    paragraph.trim(),
                    textAlign: _centerText ? TextAlign.center : TextAlign.left,
                    style: GoogleFonts.lora(
                      color: ink.withValues(alpha: .92),
                      fontSize: _fontSize,
                      height: 1.72,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if ((widget.verseReference ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote_rounded, color: widget.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.verseReference!,
                              style: GoogleFonts.playfairDisplay(
                                color: ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.provenance?.translation != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                _shortTranslation(
                                  widget.provenance!.translation!,
                                ),
                                style: GoogleFonts.inter(
                                  color: ink.withValues(alpha: .56),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.tags.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: widget.tags
                      .take(3)
                      .map(
                        (tag) => Text(
                          '#$tag',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: ink.withValues(alpha: .5),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF15121D).withValues(alpha: .92),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final stackActions =
                widget.onSecondaryAction != null &&
                (constraints.maxWidth < 340 || textScale > 1.3);
            final primary = _primaryButton();
            final secondary = _secondaryButton();
            if (stackActions) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (secondary != null) ...[
                    secondary,
                    const SizedBox(height: 10),
                  ],
                  primary,
                ],
              );
            }
            return Row(
              children: [
                if (secondary != null) ...[
                  Flexible(child: secondary),
                  const SizedBox(width: 10),
                ],
                Expanded(child: primary),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget? _secondaryButton() {
    if (widget.onSecondaryAction == null) return null;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: .24)),
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onPressed: widget.onSecondaryAction,
      icon: Icon(widget.secondaryActionIcon ?? Icons.forum_outlined),
      label: Text(
        widget.secondaryActionLabel ?? 'Más',
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _primaryButton() => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: _completed ? const Color(0xFF5F8178) : widget.accent,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 54),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    onPressed: () {
      if (!_completed) {
        HapticFeedback.mediumImpact();
        setState(() => _completed = true);
        widget.onComplete?.call();
      } else if (widget.onNext != null) {
        widget.onNext!();
      } else {
        widget.onBack();
      }
    },
    icon: Icon(_completed ? Icons.arrow_forward_rounded : Icons.check_rounded),
    label: Text(
      _completed
          ? (widget.onNext != null ? widget.completedActionLabel : 'Terminar')
          : widget.primaryActionLabel,
      maxLines: 2,
      textAlign: TextAlign.center,
    ),
  );

  String _shortTranslation(String translation) {
    if (translation == 'Reina-Valera 1909') return 'RV1909';
    return translation;
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.self_improvement_rounded,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            'No pudimos abrir esta oración',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    ),
  );

  Future<void> _showReadingSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustes de lectura',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Tamaño'),
                  Expanded(
                    child: Slider(
                      min: 16,
                      max: 24,
                      divisions: 4,
                      value: _fontSize,
                      onChanged: (value) {
                        setState(() => _fontSize = value);
                        setSheetState(() {});
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Centrar el texto'),
                subtitle: const Text('Recomendado para oraciones breves'),
                value: _centerText,
                onChanged: (value) {
                  setState(() => _centerText = value);
                  setSheetState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _estimatedMinutes(String text) =>
      (text.trim().split(RegExp(r'\s+')).length / 150).ceil().clamp(1, 20);
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: .25), color.withValues(alpha: 0)],
      ),
    ),
  );
}

class PrayerTextReadingScreen extends StatelessWidget {
  final ContentProvenance provenance;
  final String title;
  final String text;
  final String? reference;
  final Color accent;
  final String category;

  const PrayerTextReadingScreen({
    super.key,
    required this.title,
    required this.text,
    this.reference,
    required this.accent,
    this.category = 'Oración',
    this.provenance = ContentProvenance.unverified,
  });

  @override
  Widget build(BuildContext context) => PrayerReadingExperience(
    loading: false,
    provenance: provenance,
    category: category,
    title: title,
    text: text,
    verseReference: reference,
    accent: accent,
    onBack: () => Navigator.pop(context),
    onShare: () => ShareService.shareAsText(
      text: text,
      reference: [
        reference ?? title,
        if (provenance.translation != null) provenance.translation!,
      ].join(' · '),
      title: title,
    ),
  );
}
