import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/design_system.dart';
import '../faith/content_provenance.dart';
import '../features/sharing/domain/share_content.dart';
import '../services/read_aloud_service.dart';
import '../services/share_service.dart';

/// Página de lectura para oraciones, pasajes y momentos del día.
///
/// Sigue el tema de la app. Con [nocturne] se lee siempre en la paleta de la
/// noche ("Completas") con una vela encendida, como la oración antes de
/// dormir.
class PrayerReadingExperience extends StatefulWidget {
  final bool loading;
  final ContentProvenance? provenance;
  final String? error;
  final String category;
  final String? title;
  final String? text;
  final String? verseReference;
  final List<String> tags;
  final bool nocturne;
  final VoidCallback onBack;
  final VoidCallback? onRetry;
  final VoidCallback? onShare;
  final VoidCallback? onComplete;
  final VoidCallback? onNext;
  final bool initiallyCompleted;
  final String primaryActionLabel;
  final String completedActionLabel;
  final String? secondaryActionLabel;
  final VerbumIcons? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  const PrayerReadingExperience({
    super.key,
    required this.loading,
    this.provenance = ContentProvenance.unverified,
    required this.category,
    required this.onBack,
    this.nocturne = false,
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
  double _fontSize = 19;
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

  void _onPrimary() {
    if (!_completed) {
      HapticFeedback.mediumImpact();
      setState(() => _completed = true);
      widget.onComplete?.call();
    } else if (widget.onNext != null) {
      widget.onNext!();
    } else {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = Builder(builder: _buildPage);
    if (!widget.nocturne) return page;
    // La noche se lee siempre en la paleta "Completas".
    return Theme(
      data: buildVerbumTheme(
        brightness: Brightness.dark,
        pageTransitionsTheme: Theme.of(context).pageTransitionsTheme,
      ),
      child: page,
    );
  }

  Widget _buildPage(BuildContext context) {
    final p = context.palette;
    final showBody =
        !widget.loading && widget.error == null && widget.text != null;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            VProgressBar(value: _progress, height: 2, color: p.gold),
            Expanded(
              child: widget.loading
                  ? const Center(
                      child: VEmptyState(loading: true, title: 'Abriendo…'),
                    )
                  : widget.error != null
                  ? Center(
                      child: SingleChildScrollView(
                        child: VEmptyState(
                          icon: widget.nocturne
                              ? VerbumIcons.moonStars
                              : VerbumIcons.handsPraying,
                          title: 'No pudimos abrir esta oración',
                          message: widget.error,
                          actionLabel: widget.onRetry == null
                              ? null
                              : 'Intentar de nuevo',
                          onAction: widget.onRetry,
                        ),
                      ),
                    )
                  : _reading(context),
            ),
            if (showBody) _bottomAction(context),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final showCategory = constraints.maxWidth >= 360 || textScale <= 1.3;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Row(
            children: [
              VBackButton(onPressed: widget.onBack),
              Expanded(
                child: showCategory
                    ? Text(
                        widget.category.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.type.rubric.copyWith(
                          color: context.palette.inkSubtle,
                          fontSize: 9.5,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              VIconButton(
                icon: _speaking ? VerbumIcons.stop : VerbumIcons.headphones,
                semanticLabel: _speaking ? 'Detener audio' : 'Escuchar',
                variant: VIconButtonVariant.ghost,
                onPressed: _toggleReadAloud,
              ),
              VIconButton(
                icon: VerbumIcons.textAa,
                semanticLabel: 'Ajustes de lectura',
                variant: VIconButtonVariant.ghost,
                onPressed: _showReadingSettings,
              ),
              VIconButton(
                icon: VerbumIcons.shareNetwork,
                semanticLabel: 'Compartir',
                variant: VIconButtonVariant.ghost,
                onPressed: widget.onShare,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reading(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final paragraphs = (widget.text ?? '')
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
    final bodyStyle = type.scripture.copyWith(
      fontSize: _fontSize,
      height: 1.62,
    );
    final align = _centerText ? TextAlign.center : TextAlign.left;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      // Ocupa toda la altura: con el Stack por defecto el scroll se encoge al
      // contenido y los textos cortos quedan centrados verticalmente.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, if (current != null) current],
      ),
      child: SingleChildScrollView(
        key: ValueKey(widget.text),
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.nocturne) ...[
                  const Center(child: VCandle()),
                  Text(
                    'Antes de dormir',
                    textAlign: TextAlign.center,
                    style: type.rubric.copyWith(color: p.gold),
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  Text(
                    '${_estimatedMinutes(widget.text ?? '')} MIN DE LECTURA',
                    textAlign: TextAlign.center,
                    style: type.rubric,
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  widget.title ?? '',
                  textAlign: TextAlign.center,
                  style: type.display.copyWith(fontSize: 32, height: 1.1),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 36, height: 1, color: p.gold),
                    const SizedBox(width: 10),
                    VIcon(
                      VerbumIcons.cross,
                      weight: VIconWeight.fill,
                      size: 12,
                      color: p.gold,
                    ),
                    const SizedBox(width: 10),
                    Container(width: 36, height: 1, color: p.gold),
                  ],
                ),
                const SizedBox(height: 26),
                for (var i = 0; i < paragraphs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    // La capitular solo luce en párrafos de cierta extensión; en
                    // avisos o frases breves se ve forzada.
                    child: i == 0 && !_centerText && paragraphs[i].length >= 120
                        ? VDropCapText(paragraphs[i], style: bodyStyle)
                        : Text(
                            paragraphs[i],
                            textAlign: align,
                            style: bodyStyle,
                          ),
                  ),
                if ((widget.verseReference ?? '').isNotEmpty)
                  _citation(context),
                if (widget.tags.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final tag in widget.tags.take(3))
                        Text('#$tag', style: type.caption),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _citation(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final translation = widget.provenance?.translation;
    return VSurfaceCard(
      tone: VSurfaceTone.muted,
      radius: VerbumRadius.tile,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          VIcon(
            VerbumIcons.quotes,
            weight: VIconWeight.fill,
            size: 20,
            color: p.rubric,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.verseReference!, style: type.citation),
                if (translation != null)
                  Text(_shortTranslation(translation), style: type.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction(BuildContext context) {
    final p = context.palette;
    final primary = VButton(
      label: _completed
          ? (widget.onNext != null ? widget.completedActionLabel : 'Terminar')
          : widget.primaryActionLabel,
      icon: _completed ? VerbumIcons.arrowRight : VerbumIcons.check,
      iconLeading: !_completed,
      expanded: true,
      onPressed: _onPrimary,
    );
    final secondary = widget.onSecondaryAction == null
        ? null
        : VButton(
            label: widget.secondaryActionLabel ?? 'Más',
            icon: widget.secondaryActionIcon ?? VerbumIcons.chatsCircle,
            iconLeading: true,
            variant: VButtonVariant.outlined,
            expanded: true,
            onPressed: widget.onSecondaryAction,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final stack =
                  secondary != null &&
                  (constraints.maxWidth < 380 || textScale > 1.3);
              if (secondary == null) return primary;
              if (stack) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [secondary, const SizedBox(height: 8), primary],
                );
              }
              return Row(
                children: [
                  Expanded(child: secondary),
                  const SizedBox(width: 10),
                  Expanded(child: primary),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _shortTranslation(String translation) =>
      translation == 'Reina-Valera 1909' ? 'RV1909' : translation;

  Future<void> _showReadingSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustes de lectura',
                style: sheetContext.type.title.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Tamaño', style: sheetContext.type.bodyStrong),
                  Expanded(
                    child: Slider(
                      min: 16,
                      max: 25,
                      divisions: 9,
                      value: _fontSize,
                      label: '${_fontSize.round()}',
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
                title: Text(
                  'Centrar el texto',
                  style: sheetContext.type.bodyStrong,
                ),
                subtitle: Text(
                  'Recomendado para oraciones breves',
                  style: sheetContext.type.caption,
                ),
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

class PrayerTextReadingScreen extends StatelessWidget {
  final ContentProvenance provenance;
  final String title;
  final String text;
  final String? reference;
  final String category;

  const PrayerTextReadingScreen({
    super.key,
    required this.title,
    required this.text,
    this.reference,
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
    onBack: () => Navigator.pop(context),
    onShare: () => ShareService.openComposer(
      context,
      ShareContent(
        title: title,
        body: text,
        reference: reference ?? title,
        sourceLabel: provenance.translation,
        kind: provenance == ContentProvenance.bible
            ? RegExp(
                    r'^Salmos?\s+\d',
                    caseSensitive: false,
                  ).hasMatch(reference ?? title)
                  ? ShareContentKind.psalm
                  : ShareContentKind.verse
            : ShareContentKind.prayer,
      ),
    ),
  );
}
