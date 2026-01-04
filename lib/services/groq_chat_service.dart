import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Represents a chat message in the conversation.
class ChatMessage {
  final String role; // 'user', 'assistant', or 'system'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
    );
  }

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);

  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);
}

/// Response from the chatWithGroq Cloud Function.
class ChatResponse {
  final List<String> messages;
  final String rawContent;

  ChatResponse({required this.messages, required this.rawContent});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final msgList = (json['messages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return ChatResponse(
      messages: msgList,
      rawContent: json['rawContent'] as String? ?? '',
    );
  }
}

/// Service to interact with the chatWithGroq Firebase Cloud Function.
class GroqChatService {
  GroqChatService._();
  static final GroqChatService _instance = GroqChatService._();
  factory GroqChatService() => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Sends a message to the Groq-powered chatbot and returns the response.
  ///
  /// [userText] - The user's message text.
  /// [conversation] - Previous messages in the conversation for context.
  Future<ChatResponse> sendMessage({
    required String userText,
    List<ChatMessage> conversation = const [],
  }) async {
    try {
      final callable = _functions.httpsCallable('chatWithGroq');
      final result = await callable.call<Map<String, dynamic>>({
        'userText': userText,
        'conversation': conversation.map((m) => m.toJson()).toList(),
      });

      final data = result.data;
      return ChatResponse.fromJson(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('FirebaseFunctionsException: ${e.code} - ${e.message}');
      throw Exception('Error en el chat: ${e.message}');
    } catch (e) {
      debugPrint('GroqChatService error: $e');
      throw Exception('Error al conectar con el chat: $e');
    }
  }
}
