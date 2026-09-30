import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/verbum_header_actions.dart';
import '../services/groq_chat_service.dart' as groq;
import '../providers/auth_provider.dart';
import '../design_system/design_system.dart';

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
    ChatMessage(
      text: 'Hola, soy tu compañero espiritual. ¿En qué te acompaño hoy?',
    ),
  ];
  final List<groq.ChatMessage> _conversationHistory = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final groq.GroqChatService _chatService = groq.GroqChatService();
  bool _isLoading = false;

  String _errorToMessage(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return 'Lo siento, hubo un error. Intenta de nuevo.';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userText = text.trim();

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Check if user is authenticated
    final auth = context.read<AuthProvider>();
    if (!auth.isSignedIn) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Para usar el chat con IA, necesitas iniciar sesión. Ve a Perfil → Continuar con Google.',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await _chatService.sendMessage(
        userText: userText,
        conversation: _conversationHistory,
      );

      // Add user message to history
      _conversationHistory.add(groq.ChatMessage.user(userText));

      // Add assistant response(s) to UI and history
      if (mounted) {
        setState(() {
          for (final msg in response.messages) {
            _messages.add(ChatMessage(text: msg, isUser: false));
          }
          _isLoading = false;
        });
        // Add full response to history
        _conversationHistory.add(
          groq.ChatMessage.assistant(response.rawContent),
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: _errorToMessage(e), isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppScaffold(
      centerTitle: false,
      titleWidget: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.goldSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: VIcon(
              VerbumIcons.chatsCircle,
              weight: VIconWeight.duotone,
              size: 21,
              color: p.gold,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acompañamiento', style: context.type.heading),
                Text(
                  'UN ESPACIO SEGURO PARA HABLAR',
                  style: context.type.rubric.copyWith(
                    color: p.gold,
                    fontSize: 8.5,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: const [VerbumHeaderActions()],
      showBanner: false,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[index];
                return TweenAnimationBuilder<double>(
                  key: ValueKey('msg_$index'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 12),
                      child: child,
                    ),
                  ),
                  child: ChatBubble(text: msg.text, isUser: msg.isUser),
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
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu mensaje',
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            VIconButton(
              icon: VerbumIcons.paperPlaneRight,
              semanticLabel: 'Enviar mensaje',
              variant: VIconButtonVariant.solid,
              size: 46,
              onPressed: _isLoading
                  ? null
                  : () => _sendMessage(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de respuesta en curso: tres puntos que respiran.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'El acompañante está escribiendo',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Opacity(
                    opacity:
                        0.3 +
                        0.7 * (1 - ((_c.value * 3 - i) % 3).clamp(0.0, 1.0)),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: p.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
