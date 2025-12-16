import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(ReadingChatMessage(text: trimmed, isUser: true));
      _messages.add(
        ReadingChatMessage(
          isUser: false,
          text:
              'Gracias por compartir. Relacionado con la lectura:\n"${widget.content}"${widget.reference != null && widget.reference!.isNotEmpty ? " (${widget.reference})" : ""}',
        ),
      );
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1C2A),
                  Color(0xFF2D2347),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.15),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.content,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            if (widget.reference != null && widget.reference!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.reference!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFFB74D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final align = msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                      final bubbleColor = msg.isUser
                          ? Colors.white.withOpacity(0.18)
                          : Colors.white.withOpacity(0.08);
                      return Column(
                        crossAxisAlignment: align,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Text(
                              msg.text,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu mensaje...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _sendMessage(_controller.text),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF6C63FF),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

