import 'package:flutter/material.dart';
import '../services/groq_chat_service.dart' as groq;
import '../services/app_analytics_service.dart';
import 'package:verbum/design_system/design_system.dart';

class ReadingChatMessage {
  final String text;
  final bool isUser;
  ReadingChatMessage({required this.text, required this.isUser});
}

/// Chat efímero asociado a un versículo/oración.
/// No guarda estado al cerrarse.
class ReadingChatScreen extends StatefulWidget {
  final String title;
  final String content;
  final String? reference;

  const ReadingChatScreen({
    super.key,
    required this.title,
    required this.content,
    this.reference,
  });

  @override
  State<ReadingChatScreen> createState() => _ReadingChatScreenState();
}

class _ReadingChatScreenState extends State<ReadingChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ReadingChatMessage> _messages = [];
  final List<groq.ChatMessage> _history = [];
  final _chatService = groq.GroqChatService();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;
    setState(() {
      _messages.add(ReadingChatMessage(text: trimmed, isUser: true));
      _loading = true;
    });
    _controller.clear();
    final contextText = _history.isEmpty
        ? 'Estoy meditando este contenido cristiano: "${widget.content}" '
              '${widget.reference?.isNotEmpty == true ? '(${widget.reference})' : ''}. '
              'Acompáñame de manera breve, cálida y práctica. Mi pregunta es: $trimmed'
        : trimmed;
    try {
      final response = await _chatService.sendMessage(
        userText: contextText,
        conversation: _history,
      );
      _history.add(groq.ChatMessage.user(contextText));
      _history.add(groq.ChatMessage.assistant(response.rawContent));
      if (!mounted) return;
      setState(() {
        for (final message in response.messages) {
          _messages.add(ReadingChatMessage(text: message, isUser: false));
        }
      });
      AppAnalyticsService.event('contextual_companion_message');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ReadingChatMessage(
            text: error.toString().replaceFirst('Exception: ', ''),
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final hasReference =
        widget.reference != null && widget.reference!.isNotEmpty;

    return Scaffold(
      backgroundColor: p.background,
      appBar: const VAppBar(title: Text('Acompañamiento')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VerbumSpace.gutter,
                4,
                VerbumSpace.gutter,
                0,
              ),
              child: VSurfaceCard(
                tone: VSurfaceTone.accent,
                padding: const EdgeInsets.all(VerbumSpace.md),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(widget.title, style: type.heading),
                      ),
                      const SizedBox(height: VerbumSpace.xs),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: SingleChildScrollView(
                          child: Text(widget.content, style: type.scripture),
                        ),
                      ),
                      if (hasReference) ...[
                        const SizedBox(height: VerbumSpace.xs),
                        Text(widget.reference!, style: type.citation),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: VerbumSpace.gutter,
                  vertical: VerbumSpace.sm,
                ),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_loading && index == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(
                            VerbumRadius.control,
                          ),
                          boxShadow: VerbumShadows.subtle(p),
                        ),
                        child: SizedBox(
                          width: 38,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: p.gold,
                            backgroundColor: p.accentSoft,
                          ),
                        ),
                      ),
                    );
                  }
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .82,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isUser ? p.inverse : p.surface,
                          borderRadius: BorderRadius.circular(
                            VerbumRadius.control,
                          ),
                          boxShadow: msg.isUser
                              ? null
                              : VerbumShadows.subtle(p),
                        ),
                        child: Text(
                          msg.text,
                          style: type.body.copyWith(
                            color: msg.isUser ? p.onInverse : p.ink,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VerbumSpace.gutter,
                0,
                VerbumSpace.gutter,
                VerbumSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje…',
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  VIconButton(
                    icon: VerbumIcons.paperPlaneRight,
                    weight: VIconWeight.fill,
                    semanticLabel: 'Enviar',
                    variant: VIconButtonVariant.solid,
                    size: 46,
                    onPressed: _loading
                        ? null
                        : () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
