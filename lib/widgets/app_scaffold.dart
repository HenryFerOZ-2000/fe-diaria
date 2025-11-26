import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.backgroundDark,
                  AppColors.surfaceDark,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.background,
                  colorScheme.tertiary.withOpacity(0.05),
                  AppColors.background,
                ],
        );

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: showAppBar
          ? AppBar(
              title: titleWidget ??
                  (title != null
                      ? Text(
                          title!,
                          style: theme.textTheme.titleLarge,
                        )
                      : null),
              centerTitle: centerTitle,
              backgroundColor: Colors.transparent,
              elevation: appBarElevation ?? 0,
              scrolledUnderElevation: 0,
              actions: actions,
              bottom: bottom,
            )
          : null,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: bgGradient,
        ),
        child: SafeArea(
          child: body,
        ),
      ),
    );
  }
}

