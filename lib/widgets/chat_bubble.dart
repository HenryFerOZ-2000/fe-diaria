import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Avatar del acompañante: una paloma sobre mantequilla.
class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.butter,
          borderRadius: BorderRadius.circular(size * .36),
        ),
        child: VIcon(
          VerbumIcons.bird,
          weight: VIconWeight.fill,
          size: size * .56,
          color: p.onButter,
        ),
      ),
    );
  }
}

/// Burbuja de conversación: el acompañante en tarjeta blanca con su avatar;
/// la persona en índigo, alineada a la derecha.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const r = Radius.circular(20);
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? p.emphasis : p.surface,
        borderRadius: BorderRadius.only(
          topLeft: isUser ? r : const Radius.circular(6),
          topRight: r,
          bottomLeft: r,
          bottomRight: isUser ? const Radius.circular(6) : r,
        ),
        boxShadow: isUser ? null : VerbumShadows.subtle(p),
      ),
      child: SelectableText(
        text,
        style: context.type.body.copyWith(
          color: isUser ? p.onEmphasis : p.ink,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[const CompanionAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                left: isUser ? 56 : 0,
                right: isUser ? 0 : 24,
              ),
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }
}
