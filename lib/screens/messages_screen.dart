import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.initialChatName});
  final String? initialChatName;
  @override State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _chats = <_ChatData>[
    _ChatData('Maria S.', 'You: Sure, I can donate tomorrow.', '10:01'),
    _ChatData('Juan D.', 'You: Hi, I accepted your blood request.', '08:07', unread: true),
  ];

  @override
  void initState() {
    super.initState();
    final name = widget.initialChatName;
    if (name != null && !_chats.any((chat) => chat.name == name)) {
      _chats.insert(0, _ChatData(name, 'New request response. Start a conversation.', 'Now', unread: true));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff7f8fa),
    appBar: AppBar(backgroundColor: const Color(0xffcf2929), foregroundColor: Colors.white, elevation: 0, title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700))),
    body: ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24), itemCount: _chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _MessageCard(
        chat: _chats[index],
        onOpen: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(name: _chats[index].name))),
        onToggleRead: () => setState(() => _chats[index].unread = !_chats[index].unread),
        onDelete: () => setState(() => _chats.removeAt(index)),
      ),
    ),
  );
}

class _ChatData {
  _ChatData(this.name, this.preview, this.time, {this.unread = false});
  final String name, preview, time;
  bool unread;
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.chat, required this.onOpen, required this.onToggleRead, required this.onDelete});
  final _ChatData chat; final VoidCallback onOpen, onToggleRead, onDelete;
  static const _red = Color(0xffcf2929);
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(19),
    child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(19), child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 4, offset: Offset(0, 2))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 13, 16, 12), child: Row(children: [
          CircleAvatar(radius: 22, backgroundColor: _red, child: Text(chat.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))),
          const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(chat.name, style: const TextStyle(color: Color(0xff101828), fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3),
            Text(chat.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff52627c), fontSize: 13.5)),
          ])), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(chat.time, style: const TextStyle(color: Color(0xff8c9ab4), fontSize: 13)), const SizedBox(height: 8),
            if (chat.unread) const CircleAvatar(radius: 4.5, backgroundColor: _red),
          ]),
        ])), const Divider(height: 1, color: Color(0xffedf0f3)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _Action(Icons.check, 'Read', const Color(0xff39a64a), onToggleRead), _Action(Icons.markunread, 'Unread', _red, onToggleRead), _Action(Icons.delete, 'Delete', _red, onDelete),
        ])),
      ]),
    )),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.text, this.color, this.onTap);
  final IconData icon; final String text; final Color color; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Color(0xff40516b), fontSize: 13.5))])));
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.name}); final String name;
  @override State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController(); final _messages = <String>['Hi! Thank you for responding to my request.'];
  @override void dispose() { _controller.dispose(); super.dispose(); }
  void _send() { final message = _controller.text.trim(); if (message.isEmpty) return; setState(() { _messages.add('You: $message'); _controller.clear(); }); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.name)), body: Column(children: [
    Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (_, index) { final message = _messages[index]; final mine = message.startsWith('You:'); return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: mine ? const Color(0xffd9283b) : Colors.white, borderRadius: BorderRadius.circular(14)), child: Text(message.replaceFirst('You: ', ''), style: TextStyle(color: mine ? Colors.white : Colors.black87)))); })),
    SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Type a message...'))), IconButton(icon: const Icon(Icons.send, color: Color(0xffd9283b)), onPressed: _send)]))),
  ]));
}
