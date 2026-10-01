import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../design_system/design_system.dart';
import 'verbum_ambient_background.dart';

/// Scaffold personalizado con diseño consistente y gradientes
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? titleWidget;

  /// A la izquierda de la barra (p. ej. [VerbumSettingsButton]).
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool showAppBar;
  final PreferredSizeWidget? bottom;
  final double? appBarElevation;
  final BannerAd? bannerAd;
  final bool showBanner;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.gradient,
    this.showAppBar = true,
    this.bottom,
    this.appBarElevation,
    this.bannerAd,
    this.showBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Guest notice (only when not signed in)
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      // Con degradado propio, el fondo continúa bajo la barra superior.
      extendBodyBehindAppBar: gradient != null,
      appBar: showAppBar
          ? VAppBar(
              leading: leading,
              title:
                  titleWidget ??
                  (title != null
                      ? Text(title!, style: theme.textTheme.titleLarge)
                      : null),
              centerTitle: centerTitle,
              actions: actions,
              bottom: bottom,
            )
          : null,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: VerbumAmbientBackground(
        gradient: gradient,
        color: backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: body),
              // Banner Ad flotante - siempre visible en la parte inferior
              if (showBanner && bannerAd != null)
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: bannerAd!.size.height.toDouble(),
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: AdWidget(ad: bannerAd!),
                )
              else if (showBanner)
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
