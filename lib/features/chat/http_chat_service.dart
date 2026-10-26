import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_models.dart';

class HttpChatService implements ChatService {
  final Uri endpoint;
  HttpChatService(this.endpoint);

  @override
  Stream<String> reply(List<ChatMessage> history) async* {
    final request = http.Request('POST', endpoint)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'messages': history
            .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
            .toList(),
      });

    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }
    yield* response.stream.transform(utf8.decoder);
  }
}