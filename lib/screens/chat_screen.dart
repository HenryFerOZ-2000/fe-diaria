import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/chat_bubble.dart';
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

  /// Para empezar con un toque.
  static const _suggestions = [
    (VerbumIcons.wind, 'Me siento ansioso y necesito calma'),
    (VerbumIcons.handHeart, 'Quiero orar por alguien'),
    (VerbumIcons.bookOpenText, 'Explícame un versículo'),
    (VerbumIcons.sun, 'Necesito esperanza hoy'),
  ];

  bool _pastCover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final signedIn = context.watch<AuthProvider>().isSignedIn;
    final started = _messages.any((m) => m.isUser);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (_pastCover ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      final past = n.metrics.pixels > 260;
                      if (past != _pastCover) setState(() => _pastCover = past);
                      return false;
                    },
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        VPhotoCover(
                          image: AssetImage(VerbumPhotos.chatBench.asset),
                          // La banca queda arriba del título.
                          alignment: const Alignment(0, .85),
                          minHeight: started ? 300 : 360,
                          bottomPadding: 28,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  VGlassButton(
                                    icon: VerbumIcons.slidersHorizontal,
                                    tooltip: 'Configuración',
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pushNamed('/settings'),
                                  ),
                                  const Spacer(),
                                  VGlassButton(
                                    icon: VerbumIcons.user,
                                    tooltip: 'Mi perfil',
                                    onPressed: () => Navigator.of(
                                      context,
                                    ).pushNamed('/profile'),
                                  ),
                                ],
                              ),
                              SizedBox(height: started ? 70 : 96),
                              Text(
                                'ACOMPAÑAMIENTO',
                                style: type.rubric.copyWith(
                                  color: p.butter,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Semantics(
                                header: true,
                                child: Text(
                                  'Un espacio seguro para hablar',
                                  style: type.display.copyWith(
                                    color: Colors.white,
                                    fontSize: 30,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cuéntame lo que llevas hoy en el corazón.',
                                style: type.body.copyWith(
                                  color: Colors.white.withValues(alpha: .9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VerbumSpace.gutter,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < _messages.length; i++)
                                TweenAnimationBuilder<double>(
                                  key: ValueKey('msg_$i'),
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
                                  child: ChatBubble(
                                    text: _messages[i].text,
                                    isUser: _messages[i].isUser,
                                  ),
                                ),
                              if (_isLoading) const _TypingIndicator(),
                              if (!started) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Puedes empezar por aquí',
                                  style: type.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (final (icon, text) in _suggestions)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: VSurfaceCard(
                                      radius: VerbumRadius.tile,
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        12,
                                        10,
                                      ),
                                      onTap: signedIn && !_isLoading
                                          ? () => _sendMessage(text)
                                          : null,
                                      semanticLabel: text,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: p.surfaceMuted,
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                            child: VIcon(
                                              icon,
                                              size: 18,
                                              color: p.rubric,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: type.bodyStrong,
                                            ),
                                          ),
                                          VIcon(
                                            VerbumIcons.arrowUpRight,
                                            size: 16,
                                            color: p.inkSubtle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  'Soy una guía con inteligencia artificial: '
                                  'te acompaño, pero no sustituyo a un '
                                  'sacerdote, pastor o profesional.',
                                  textAlign: TextAlign.center,
                                  style: type.caption,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _pastCover ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          height: MediaQuery.paddingOf(context).top,
                          color: p.background.withValues(alpha: .96),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildInput(context, signedIn: signedIn),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context, {required bool signedIn}) {
    final p = context.palette;
    final type = context.type;
    return Material(
      color: p.surface,
      elevation: 8,
      shadowColor: p.ink.withValues(alpha: .2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          10,
          VerbumSpace.gutter,
          10,
        ),
        child: signedIn
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje…',
                      ),
                      onSubmitted: _isLoading ? null : _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: _isLoading ? p.surfaceMuted : p.emphasis,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isLoading
                          ? null
                          : () => _sendMessage(_controller.text),
                      child: SizedBox.square(
                        dimension: 48,
                        child: Center(
                          child: Semantics(
                            label: 'Enviar mensaje',
                            button: true,
                            child: VIcon(
                              VerbumIcons.paperPlaneRight,
                              weight: VIconWeight.fill,
                              size: 20,
                              color: _isLoading ? p.inkSubtle : p.onEmphasis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  VIcon(VerbumIcons.lockSimple, color: p.inkSubtle),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Inicia sesión para conversar',
                      style: type.bodyStrong,
                    ),
                  ),
                  VButton(
                    label: 'Iniciar sesión',
                    compact: true,
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/welcome'),
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const CompanionAvatar(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: VerbumShadows.subtle(p),
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
                            0.7 *
                                (1 - ((_c.value * 3 - i) % 3).clamp(0.0, 1.0)),
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
          ],
        ),
      ),
    );
  }
}
