import 'package:flutter/foundation.dart';
import 'chat_models.dart';

class ChatController extends ChangeNotifier {
  final ChatService service;
  final List<ChatMessage> messages = [];
  bool isLoading = false;

  ChatController(this.service);

  Future<void> send(String text) async {
    if (text.trim().isEmpty || isLoading) return;

    messages.add(ChatMessage(isUser: true, text: text.trim()));
    final botMessage = ChatMessage(isUser: false, text: '');
    messages.add(botMessage);
    isLoading = true;
    notifyListeners();

    try {
      final history = messages.sublist(0, messages.length - 1);
      await for (final chunk in service.reply(history)) {
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