class ChatMessage {
  final bool isUser;
  String text;
  ChatMessage({required this.isUser, required this.text});
}

abstract class ChatService {
  Stream<String> reply(List<ChatMessage> history);
}