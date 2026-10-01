import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/verbum_context.dart';
import 'v_back_button.dart';

/// Barra superior compartida: transparente (el fondo de la pantalla sube
/// hasta la barra de estado sin cortes), iconos de estado según el tema y
/// el botón de regreso [VBackButton] cuando se puede volver.
class VAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.onColor = false,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  /// Sobre un fondo de color (periwinkle): textos e iconos claros.
  final bool onColor;

  static const _height = 64.0;
  static const _leadingWidth = 16 + 44 + 8.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(_height + (bottom?.preferredSize.height ?? 0));

  /// Versión fija para listas con slivers: se queda arriba al hacer scroll,
  /// sobre un fondo lavanda casi opaco.
  static Widget sliver(
    BuildContext context, {
    Widget? title,
    List<Widget>? actions,
  }) {
    final back = _impliedBack(context, null, true, false);
    return SliverAppBar(
      pinned: true,
      toolbarHeight: _height,
      backgroundColor: context.palette.background.withValues(alpha: .96),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: back == null ? null : Center(child: back),
      leadingWidth: back == null ? null : _leadingWidth,
      titleSpacing: back == null ? 18 : 4,
      title: title,
      actions: actions == null ? null : [...actions, const SizedBox(width: 12)],
      systemOverlayStyle: _overlay(
        Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  static Widget? _impliedBack(
    BuildContext context,
    Widget? leading,
    bool imply,
    bool onColor,
  ) {
    if (leading != null) return leading;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return imply && canPop ? VBackButton(onColor: onColor) : null;
  }

  static SystemUiOverlayStyle _overlay(bool dark) =>
      (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
      );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = onColor || Theme.of(context).brightness == Brightness.dark;
    final back = _impliedBack(
      context,
      leading,
      automaticallyImplyLeading,
      onColor,
    );

    return AppBar(
      toolbarHeight: _height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: back == null ? null : Center(child: back),
      leadingWidth: back == null ? null : _leadingWidth,
      titleSpacing: back == null ? 18 : 4,
      centerTitle: centerTitle,
      title: title == null
          ? null
          : DefaultTextStyle.merge(
              style: context.type.heading.copyWith(
                color: onColor ? p.onInverse : p.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: title!,
            ),
      actions: actions == null
          ? null
          : [...actions!, const SizedBox(width: 12)],
      bottom: bottom,
      systemOverlayStyle: _overlay(dark),
    );
  }
}
