import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/chat_bubble.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, this.isUser = false});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(text: 'Hola, soy tu compañero de oración. ¿En qué te acompaño hoy?'),
  ];
  final TextEditingController _controller = TextEditingController();

  final Map<String, String> _cannedResponses = {
    'necesito una oración': 'Aquí tienes una oración breve: "Señor, dame paz y guía mis pasos hoy. Amén."',
    'me siento triste': 'Lo siento. Respira hondo. "Dios está cerca de los que tienen el corazón quebrantado." (Salmo 34:18)',
    'estoy preocupado': 'Entrega tus cargas: "Echa sobre el Señor tu carga y Él te sustentará." (Salmo 55:22)',
    'quiero un versículo': 'Proverbios 3:5-6 — Confía en el Señor de todo corazón y Él enderezará tus caminos.',
    'dame ánimo': 'Eres amado y visto. "Todo lo puedo en Cristo que me fortalece." (Fil 4:13)',
    'ora por mí': 'Oremos: "Padre, cuida de quien lee esto. Dale paz, fuerza y esperanza. Amén."',
  };

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true));
    });
    _controller.clear();
    _reply(text);
  }

  void _reply(String userText) {
    final lower = userText.toLowerCase();
    String reply = 'Estoy aquí contigo. ¿Quieres que oremos juntos?';
    for (final entry in _cannedResponses.entries) {
      if (lower.contains(entry.key)) {
        reply = entry.value;
        break;
      }
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chat',
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                );
              },
            ),
          ),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje',
                hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6)),
                filled: true,
                fillColor: colorScheme.surface.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _sendMessage(_controller.text),
            icon: const Icon(Icons.send_rounded),
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

