import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../application/share_card_layout.dart';
import '../domain/share_card_format.dart';
import '../domain/share_content.dart';
import '../domain/share_page.dart';
import '../domain/share_visual_style.dart';

/// The single fixed composition used for both the preview and PNG export.
/// Only the entire output-space design scales; spiritual copy never shrinks.
class VerbumShareCard extends StatelessWidget {
  const VerbumShareCard({
    super.key,
    required this.content,
    required this.page,
    required this.format,
    required this.style,
  });

  final ShareContent content;
  final SharePage page;
  final ShareCardFormat format;
  final ShareVisualStyle style;

  @override
  Widget build(BuildContext context) {
    final layout = ShareCardLayout(format);
    final palette = _CardPalette.forStyle(style);
    final reference = content.reference;
    final multiplePages = page.total > 1;

    return AspectRatio(
      aspectRatio: layout.size.aspectRatio,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: layout.size,
          child: MediaQuery(
            // The fixed export composition must retain the paginator's exact
            // metrics even when the surrounding controls use accessibility
            // typography. Preserve all unrelated inherited media settings.
            data: (MediaQuery.maybeOf(context) ?? const MediaQueryData())
                .copyWith(textScaler: TextScaler.noScaling, boldText: false)
                .applyTextStyleOverrides(
                  lineHeightScaleFactorOverride: null,
                  letterSpacingOverride: null,
                  wordSpacingOverride: null,
                  paragraphSpacingOverride: null,
                ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'VerbumInter',
                fontSize: 26,
                color: palette.ink,
                decoration: TextDecoration.none,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.background,
                    stops: const [0, .55, 1],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      top: -250,
                      right: -250,
                      child: _AmbientCircle(color: palette.halo, diameter: 920),
                    ),
                    Positioned(
                      bottom: -340,
                      left: -290,
                      child: _AmbientCircle(color: palette.halo, diameter: 780),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: palette.accent.withValues(alpha: .4),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.horizontalInset,
                        vertical: layout.verticalInset,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: layout.logoRegionHeight,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/icon/icon.png',
                                    key: const Key('share-card-logo'),
                                    semanticLabel: 'Logotipo de Verbum',
                                    width: 76,
                                    height: 76,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Text(
                                  'VERBUM',
                                  style: TextStyle(
                                    fontSize: 26,
                                    letterSpacing: 6,
                                    fontWeight: FontWeight.w600,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(width: 36),
                                Expanded(
                                  child: Text(
                                    content.title,
                                    textAlign: TextAlign.end,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 25,
                                      height: 1.4,
                                      color: palette.metadata,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox.fromSize(
                            size: layout.bodyBox(
                              reservePageMarker: multiplePages,
                            ),
                            child: Center(
                              child: Text(
                                page.body.trim(),
                                key: const Key('share-card-body'),
                                textAlign: TextAlign.center,
                                style: layout.bodyStyle.copyWith(
                                  color: palette.ink,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: layout.referenceRegionHeight,
                            child: Center(
                              child: reference == null || reference.isEmpty
                                  ? const SizedBox.shrink()
                                  : Text(
                                      reference,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 29,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                        color: palette.metadata,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(
                            height: layout.footerRegionHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 2,
                                  color: palette.accent,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'LA PALABRA CONTIGO',
                                  style: TextStyle(
                                    fontSize: 19,
                                    letterSpacing: 5,
                                    color: palette.metadata,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (multiplePages)
                            SizedBox(
                              height: layout.pageMarkerRegionHeight,
                              child: Center(
                                child: Text(
                                  '${page.index} de ${page.total}',
                                  semanticsLabel:
                                      'Página ${page.index} de ${page.total}',
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: palette.metadata,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) => Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: .13), width: 2),
      gradient: RadialGradient(
        colors: [color.withValues(alpha: .16), color.withValues(alpha: 0)],
      ),
    ),
  );
}

class _CardPalette {
  const _CardPalette({
    required this.background,
    required this.ink,
    required this.metadata,
    required this.accent,
    required this.halo,
  });

  final List<Color> background;
  final Color ink;
  final Color metadata;
  final Color accent;
  final Color halo;

  static _CardPalette forStyle(ShareVisualStyle style) => switch (style) {
    ShareVisualStyle.sereneLight => const _CardPalette(
      background: [AppColors.surface, Color(0xFFF3EEE5), Color(0xFFEAE4F0)],
      ink: AppColors.primaryDark,
      metadata: AppColors.primary,
      accent: AppColors.secondary,
      halo: AppColors.secondary,
    ),
    ShareVisualStyle.contemplativeNight => const _CardPalette(
      background: [Color(0xFF15121D), AppColors.primaryDark, Color(0xFF17141F)],
      ink: AppColors.surface,
      metadata: Color(0xFFE2C998),
      accent: Color(0xFFD8B875),
      halo: AppColors.secondary,
    ),
    ShareVisualStyle.livingTradition => const _CardPalette(
      background: [AppColors.primaryDark, AppColors.primary, Color(0xFF60475B)],
      ink: AppColors.surface,
      metadata: Color(0xFFF0D8A7),
      accent: Color(0xFFD8B875),
      halo: AppColors.secondary,
    ),
  };
}
