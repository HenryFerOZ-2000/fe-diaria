import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/auth_provider.dart';
import '../design_system/design_system.dart';
import 'verbum_ambient_background.dart';

/// Scaffold personalizado con diseño consistente y gradientes
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? titleWidget;
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
  final bool showGuestNotice;
  final BannerAd? bannerAd;
  final bool showBanner;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
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
    this.showGuestNotice = true,
    this.bannerAd,
    this.showBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Guest notice (only when not signed in)
    Widget? guestNotice;
    if (showGuestNotice) {
      final auth = Provider.of<AuthProvider?>(context, listen: true);
      final isGuest = auth == null || !auth.isSignedIn;
      if (isGuest) {
        final p = context.palette;
        guestNotice = Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: BorderRadius.circular(VerbumRadius.control),
          ),
          child: Row(
            children: [
              VIcon(VerbumIcons.info, size: 18, color: p.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Modo invitado: inicia sesión para sincronizar rachas, favoritos y progreso.',
                  style: context.type.caption.copyWith(
                    color: p.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final authProv = Provider.of<AuthProvider?>(
                    context,
                    listen: false,
                  );
                  if (authProv == null) {
                    Navigator.of(context).pushNamed('/welcome');
                    return;
                  }
                  try {
                    await authProv.signIn();
                    if (context.mounted && authProv.isSignedIn) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
                    }
                  } catch (e) {
                    final err = e.toString().replaceFirst('Exception: ', '');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            err.length > 120
                                ? '${err.substring(0, 120)}...'
                                : err,
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Iniciar sesión',
                  style: context.type.caption.copyWith(
                    color: context.palette.rubric,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      // Con degradado propio, el fondo continúa bajo la barra superior.
      extendBodyBehindAppBar: gradient != null,
      appBar: showAppBar
          ? VAppBar(
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
              if (guestNotice != null) guestNotice,
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
