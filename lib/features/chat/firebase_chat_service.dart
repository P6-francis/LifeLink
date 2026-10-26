import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'chat_models.dart';

class FirebaseChatService implements ChatService {
  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.8-flash',
  );

  @override
  Stream<String> reply(List<ChatMessage> history) async* {
    final contents = history
        .where((m) => m.text.isNotEmpty)
        .map((m) => m.isUser
            ? Content.text(m.text)
            : Content.model([TextPart(m.text)]))
        .toList();

    try {
      await for (final chunk in _model.generateContentStream(contents)) {
        final text = chunk.text;
        if (text != null) yield text;
      }
    } catch (e) {
      debugPrint('FIREBASE AI ERROR: $e');
      rethrow;
    }
  }
}