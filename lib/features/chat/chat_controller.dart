import 'package:flutter/foundation.dart';
import 'chat_models.dart';

class ChatController extends ChangeNotifier {
  final ChatService service;
  final List<ChatMessage> messages = [];
  bool isLoading = false;

  ChatController(this.service) {
    // The greeting is always the first message in the list.
    messages.add(
      ChatMessage(
        isUser: false,
        text: 'Hi! I\'m the LifeLink assistant. I can help you find donors, '
            'understand blood types, or create a blood request. '
            'How can I help you today?',
      ),
    );
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty || isLoading) return;

    messages.add(ChatMessage(isUser: true, text: text.trim()));
    final botMessage = ChatMessage(isUser: false, text: '');
    messages.add(botMessage);
    isLoading = true;
    notifyListeners();

    try {
      // Skip the greeting (index 0) so the AI only sees the real conversation.
      final history = messages.sublist(1, messages.length - 1);
      await for (final chunk in service
          .reply(history)
          .timeout(const Duration(seconds: 45))) {
        botMessage.text += chunk;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CHAT ERROR: $e');
      botMessage.text = botMessage.text.isEmpty
          ? 'Something went wrong. Please try again.'
          : '${botMessage.text}\n\n[Connection interrupted]';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}