import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Burbuja de conversación: el acompañante en papel con filete, la persona
/// en el tono de apoyo, alineada a la derecha.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const r = Radius.circular(18);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? p.surfaceMuted : p.surface,
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: isUser ? r : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : r,
          ),
          border: isUser ? null : Border.all(color: p.line),
        ),
        child: SelectableText(
          text,
          style: context.type.body.copyWith(
            color: p.ink,
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
