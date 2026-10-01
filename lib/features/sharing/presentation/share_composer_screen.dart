import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../widgets/verbum_ambient_background.dart';
import '../../../widgets/verbum_header_actions.dart';
import '../application/share_export_coordinator.dart';
import '../application/share_paginator.dart';
import '../domain/share_card_format.dart';
import '../domain/share_content.dart';
import '../domain/share_page.dart';
import '../domain/share_visual_style.dart';
import 'verbum_share_card.dart';
import 'package:verbum/design_system/design_system.dart';

class ShareComposerScreen extends StatefulWidget {
  const ShareComposerScreen({
    super.key,
    required this.content,
    required this.coordinator,
  });

  final ShareContent content;
  final ShareExportCoordinator coordinator;

  @override
  State<ShareComposerScreen> createState() => _ShareComposerScreenState();
}

enum _ExportAction { share, save, copy, shareText }

class _ShareComposerScreenState extends State<ShareComposerScreen> {
  final _captureKey = GlobalKey();
  ShareCardFormat _format = ShareCardFormat.portrait;
  late ShareVisualStyle _style;
  late List<SharePage> _pages;
  int _page = 0;
  bool _busy = false;
  int _capturingPage = 0;
  double _styleDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _style = ShareStyleResolver.resolve(widget.content);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _paginate();
  }

  void _paginate() {
    _pages = const SharePaginator().paginate(
      widget.content,
      format: _format,
      textDirection: Directionality.of(context),
    );
    _page = _page.clamp(0, _pages.length - 1);
  }

  void _selectFormat(ShareCardFormat value) {
    if (_busy || value == _format) return;
    setState(() {
      _format = value;
      _page = 0;
      _paginate();
    });
  }

  Future<Uint8List> _captureCurrentPage() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) throw const ShareExportFailure.render();
    final boundary = _captureKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
      throw const ShareExportFailure.render();
    }
    final target = _format.pixelSize;
    final image = await boundary.toImage(
      pixelRatio: target.width / boundary.size.width,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const ShareExportFailure.render();
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      // Check the encoded output as well as the logical canvas before any
      // page is handed to the export coordinator's write phase.
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        try {
          if (frame.image.width != target.width ||
              frame.image.height != target.height) {
            throw const ShareExportFailure.render();
          }
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
      return bytes;
    } finally {
      image.dispose();
    }
  }

  Future<List<Uint8List>> _renderPages() async {
    final originalPage = _page;
    final images = <Uint8List>[];
    try {
      await precacheImage(const AssetImage('assets/icon/icon.png'), context);
      for (var index = 0; index < _pages.length; index++) {
        if (!mounted) throw const ShareExportFailure.render();
        setState(() {
          _page = index;
          _capturingPage = index + 1;
        });
        images.add(await _captureCurrentPage());
      }
      return images;
    } catch (error) {
      throw ShareExportFailure.render(error);
    } finally {
      if (mounted) setState(() => _page = originalPage);
    }
  }

  Future<void> _export(
    _ExportAction action, {
    bool closeOnShared = false,
  }) async {
    if (_busy) return;
    final composerRoute = ModalRoute.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _busy = true;
      _capturingPage = 0;
    });
    String? message;
    ShareExportFailure? failure;
    var shouldClose = false;
    try {
      switch (action) {
        case _ExportAction.share:
          final result = await widget.coordinator.share(
            content: widget.content,
            renderPages: _renderPages,
          );
          shouldClose = closeOnShared && result == ShareExportResult.shared;
        case _ExportAction.save:
          final result = await widget.coordinator.save(
            content: widget.content,
            renderPages: _renderPages,
          );
          if (result == ShareExportResult.saved) {
            message = 'Tarjeta guardada en tu galería';
          }
        case _ExportAction.copy:
          await widget.coordinator.copy(widget.content);
          message = 'Texto y enlace copiados';
        case _ExportAction.shareText:
          await widget.coordinator.shareText(widget.content);
      }
    } on ShareExportFailure catch (error) {
      failure = error;
    } catch (error) {
      failure = ShareExportFailure(
        ShareExportStage.share,
        'No pudimos completar la acción.',
        error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || composerRoute?.isActive != true) return;
    if (shouldClose) {
      final navigator = composerRoute!.navigator!;
      if (composerRoute.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(composerRoute);
      }
      return;
    }
    if (failure != null || message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(failure?.userMessage ?? message!),
              if (action == _ExportAction.share &&
                  failure?.stage == ShareExportStage.share)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.inversePrimary,
                  ),
                  onPressed: () => _export(_ExportAction.shareText),
                  child: const Text('Compartir como texto'),
                ),
            ],
          ),
          action: failure == null
              ? null
              : SnackBarAction(
                  label: 'Reintentar',
                  onPressed: () => _export(action),
                ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        body: VerbumAmbientBackground(
          child: Stack(
            children: [
              ExcludeSemantics(
                excluding: _busy,
                child: IgnorePointer(
                  ignoring: _busy,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final constrained =
                                  constraints.maxHeight < 640 ||
                                  MediaQuery.textScalerOf(context).scale(16) >
                                      24;
                              final children = <Widget>[
                                _header(),
                                if (constrained)
                                  SizedBox(height: 280, child: _preview())
                                else
                                  Expanded(child: _preview()),
                                if (_pages.length > 1) _pageNavigation(),
                                _compactControls(_styles()),
                                const SizedBox(height: 12),
                                _compactControls(_formats()),
                                const SizedBox(height: 16),
                              ];
                              final content = Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  mainAxisSize: constrained
                                      ? MainAxisSize.min
                                      : MainAxisSize.max,
                                  children: children,
                                ),
                              );
                              return constrained
                                  ? SingleChildScrollView(child: content)
                                  : content;
                            },
                          ),
                        ),
                        _compactControls(_dock()),
                      ],
                    ),
                  ),
                ),
              ),
              if (_busy) ...[
                ModalBarrier(
                  dismissible: false,
                  color: scheme.scrim.withValues(alpha: .45),
                ),
                Center(
                  child: Semantics(
                    liveRegion: true,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _capturingPage == 0
                                  ? 'Preparando…'
                                  : 'Creando tarjeta $_capturingPage de ${_pages.length}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactControls(Widget child) =>
      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2, child: child);

  Widget _header() => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CREA Y COMPARTE',
                style: TextStyle(
                  fontFamily: 'VerbumInter',
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comparte la Palabra',
                style: TextStyle(
                  fontFamily: 'VerbumPlayfair',
                  fontSize: 26,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        VerbumHeaderButton(
          icon: VerbumIcons.close,
          tooltip: 'Cerrar',
          onPressed: () {
            if (!_busy) Navigator.of(context).maybePop();
          },
        ),
      ],
    ),
  );

  Widget _preview() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: _format.pixelSize,
          child: RepaintBoundary(
            key: _captureKey,
            child: VerbumShareCard(
              content: widget.content,
              page: _pages[_page],
              format: _format,
              style: _style,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _pageNavigation() => Row(
    key: const Key('share-page-navigation'),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        tooltip: 'Página anterior',
        onPressed: _busy || _page == 0 ? null : () => setState(() => _page--),
        icon: const VIcon(VerbumIcons.caretLeft),
      ),
      Flexible(
        child: Text(
          '${_page + 1} de ${_pages.length}',
          semanticsLabel: 'Página ${_page + 1} de ${_pages.length}',
        ),
      ),
      IconButton(
        tooltip: 'Página siguiente',
        onPressed: _busy || _page == _pages.length - 1
            ? null
            : () => setState(() => _page++),
        icon: const VIcon(VerbumIcons.caretRight),
      ),
    ],
  );

  Widget _styles() => GestureDetector(
    key: const Key('share-style-carousel'),
    onHorizontalDragStart: _busy ? null : (_) => _styleDragDistance = 0,
    onHorizontalDragUpdate: _busy
        ? null
        : (details) => _styleDragDistance += details.delta.dx,
    onHorizontalDragEnd: _busy
        ? null
        : (_) {
            if (_styleDragDistance == 0) return;
            final delta = _styleDragDistance < 0 ? 1 : -1;
            setState(
              () => _style =
                  ShareVisualStyle.values[(_style.index + delta).clamp(
                    0,
                    ShareVisualStyle.values.length - 1,
                  )],
            );
          },
    child: Row(
      children: [
        for (final style in ShareVisualStyle.values)
          Expanded(
            child: Semantics(
              selected: _style == style,
              button: true,
              label: _styleLabel(style),
              child: InkWell(
                key: Key('share-style-${style.name}'),
                onTap: _busy ? null : () => setState(() => _style = style),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      Container(
                        height: 42,
                        width: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _style == style
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.transparent,
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            colors: switch (style) {
                              ShareVisualStyle.sereneLight => const [
                                Color(0xFFFFFFFF),
                                Color(0xFFE5E7F8),
                              ],
                              ShareVisualStyle.contemplativeNight => const [
                                Color(0xFF10122A),
                                Color(0xFF1A1D3A),
                              ],
                              ShareVisualStyle.livingTradition => const [
                                Color(0xFF3A3C8E),
                                Color(0xFF6F72D3),
                              ],
                            },
                          ),
                        ),
                        child: VIcon(
                          _style == style
                              ? VerbumIcons.check
                              : VerbumIcons.sparkle,
                          size: 20,
                          color: style == ShareVisualStyle.sereneLight
                              ? const Color(0xFF3A3C8E)
                              : const Color(0xFFF4DF7A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ExcludeSemantics(
                        child: Text(
                          _styleLabel(style),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'VerbumInter',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  String _styleLabel(ShareVisualStyle style) => switch (style) {
    ShareVisualStyle.sereneLight => 'Luz serena',
    ShareVisualStyle.contemplativeNight => 'Noche contemplativa',
    ShareVisualStyle.livingTradition => 'Tradición viva',
  };

  Widget _formats() => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .75),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        for (final format in ShareCardFormat.values)
          Expanded(
            child: Semantics(
              key: Key('share-format-${format.name}'),
              selected: _format == format,
              button: true,
              label: 'Formato ${format.label}',
              child: TextButton(
                onPressed: _busy ? null : () => _selectFormat(format),
                style: TextButton.styleFrom(
                  backgroundColor: _format == format
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  format.label,
                  style: const TextStyle(fontFamily: 'VerbumInter'),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _dock() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
    child: Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Guardar',
              onPressed: _busy ? null : () => _export(_ExportAction.save),
              icon: const VIcon(VerbumIcons.downloadSimple),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: 'Compartir',
                child: FilledButton.icon(
                  key: const Key('share-primary-action'),
                  onPressed: _busy
                      ? null
                      : () => _export(_ExportAction.share, closeOnShared: true),
                  icon: const VIcon(VerbumIcons.shareNetwork, size: 18),
                  label: const Text(
                    'Compartir',
                    style: TextStyle(fontFamily: 'VerbumInter'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              key: const Key('share-more-actions'),
              tooltip: 'Más opciones',
              enabled: !_busy,
              onSelected: (_) => _export(_ExportAction.copy),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Text('Copiar texto y enlace'),
                ),
              ],
              icon: const VIcon(VerbumIcons.dotsThree),
            ),
          ],
        ),
      ),
    ),
  );
}
