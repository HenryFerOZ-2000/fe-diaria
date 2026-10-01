import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system/design_system.dart';
import '../providers/auth_provider.dart';

/// La única invitación a iniciar sesión de la app.
///
/// * Tarjeta ([SignInPrompt.new]): dentro del contenido, explica qué se
///   gana. Desaparece sola si ya hay sesión.
/// * Barra ([SignInPrompt.bar]): ocupa el lugar de un campo de texto
///   (comentar, conversar).
/// * Hoja ([SignInPrompt.ask]): al intentar algo que requiere sesión.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({
    super.key,
    this.title = 'Guarda tu camino',
    this.message =
        'Inicia sesión para conservar tu constancia, favoritos y progreso '
        'en todos tus dispositivos.',
    this.margin = EdgeInsets.zero,
  }) : _bar = false;

  const SignInPrompt.bar({super.key, required this.title})
    : message = null,
      margin = EdgeInsets.zero,
      _bar = true;

  final String title;
  final String? message;
  final bool _bar;

  /// Espacio alrededor de la tarjeta, solo cuando se muestra.
  final EdgeInsetsGeometry margin;

  static void _signIn(BuildContext context) =>
      Navigator.of(context).pushNamed('/welcome');

  /// Muestra la invitación en una hoja; [title] dice para qué hace falta.
  static Future<void> ask(BuildContext context, {required String title}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          0,
          VerbumSpace.gutter,
          24,
        ),
        child: _Card(
          title: title,
          message:
              'Con tu cuenta puedes comentar, orar con la comunidad y '
              'guardar tu camino.',
          onSignIn: () {
            Navigator.of(sheetContext).pop();
            _signIn(context);
          },
          elevated: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().isSignedIn) return const SizedBox();
    if (!_bar) {
      return Padding(
        padding: margin,
        child: _Card(
          title: title,
          message: message,
          onSignIn: () => _signIn(context),
        ),
      );
    }
    return Row(
      children: [
        const _Badge(size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.type.bodyStrong,
          ),
        ),
        const SizedBox(width: 8),
        VButton(
          label: 'Iniciar sesión',
          compact: true,
          onPressed: () => _signIn(context),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.butter,
        borderRadius: BorderRadius.circular(size * .34),
      ),
      child: VIcon(VerbumIcons.userCircle, size: size * .52, color: p.onButter),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.onSignIn,
    this.message,
    this.elevated = true,
  });

  final String title;
  final String? message;
  final VoidCallback onSignIn;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const _Badge(),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: type.heading.copyWith(fontSize: 17)),
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 10),
          Text(message!, style: type.body.copyWith(color: p.inkMuted)),
        ],
        const SizedBox(height: 16),
        VButton(
          label: 'Iniciar sesión',
          icon: VerbumIcons.signIn,
          iconLeading: true,
          expanded: true,
          onPressed: onSignIn,
        ),
      ],
    );
    return elevated
        ? VSurfaceCard(
            radius: VerbumRadius.card,
            padding: const EdgeInsets.all(18),
            child: content,
          )
        : content;
  }
}
