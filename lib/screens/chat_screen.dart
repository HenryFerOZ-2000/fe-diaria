import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/chat_bubble.dart';
import '../services/groq_chat_service.dart' as groq;
import '../providers/auth_provider.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';

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
    ChatMessage(text: 'Hola, soy tu compañero espiritual. ¿En qué te acompaño hoy?'),
  ];
  final List<groq.ChatMessage> _conversationHistory = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final groq.GroqChatService _chatService = groq.GroqChatService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _isLoading = false;
  bool _adsRemoved = false;

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
        _messages.add(ChatMessage(
          text: 'Para usar el chat con IA, necesitas iniciar sesión. Ve a Perfil → Continuar con Google.',
          isUser: false,
        ));
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
        _conversationHistory.add(groq.ChatMessage.assistant(response.rawContent));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _errorToMessage(e),
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    if (_adsRemoved) return;
    
    _adsService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        if (mounted && !_adsRemoved) {
          setState(() {
            _bannerAd = ad;
          });
        } else {
          ad.dispose();
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Failed to load banner ad: $error');
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_adsRemoved && _bannerAd == null) {
            _loadBannerAd();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chat Espiritual',
      showBanner: !_adsRemoved,
      bannerAd: _bannerAd,
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

  Widget _buildTypingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 40, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(0),
          ),
          border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
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
                color: colorScheme.onSurface.withOpacity(0.7),
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

