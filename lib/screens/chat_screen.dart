import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/verbum_header_actions.dart';
import '../services/groq_chat_service.dart' as groq;
import '../providers/auth_provider.dart';

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
    return AppScaffold(
      centerTitle: false,
      titleWidget: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF493878), Color(0xFFB58A45)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acompañamiento',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'UN ESPACIO SEGURO PARA HABLAR',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
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
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator(context);
                }
                final msg = _messages[index];
                return TweenAnimationBuilder<double>(
                  key: ValueKey('msg_$index'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 12),
                        child: child,
                      ),
                    );
                  },
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

  Widget _buildTypingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 40, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(
            16,
          ).copyWith(bottomLeft: const Radius.circular(0)),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Pensando...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
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
            color: colorScheme.primary.withValues(alpha: 0.08),
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
                hintStyle: GoogleFonts.inter(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: colorScheme.surface.withValues(alpha: 0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            onPressed: () => _sendMessage(_controller.text),
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

/// Botón de envío circular con gradiente y animación de presión.
class _SendButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;

  const _SendButton({required this.onPressed, required this.color});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 120),
    vsync: this,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.88,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, widget.color.withValues(alpha: 0.75)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
