import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../widgets/async_state_view.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const _red = Color(0xffcf2929);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in to view messages.')));
    }
    return Scaffold(
      backgroundColor: const Color(0xfff7f8fa),
      appBar: AppBar(backgroundColor: _red, foregroundColor: Colors.white, elevation: 0, title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AsyncStateView.error(error: snapshot.error);
          if (!snapshot.hasData) return const AsyncStateView.loading(label: 'Loading conversations...');
          final chats = snapshot.data!.docs.toList()..sort((a, b) => _timestamp(b.data()['updatedAt']).compareTo(_timestamp(a.data()['updatedAt'])));
          if (chats.isEmpty) return const AsyncStateView.empty(title: 'No conversations yet', message: 'Respond to a blood request to start a conversation.', icon: Icons.forum_outlined);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ConversationCard(chat: chats[index], currentUserId: user.uid),
          );
        },
      ),
    );
  }

  static DateTime _timestamp(dynamic value) => value is Timestamp ? value.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.chat, required this.currentUserId});
  final QueryDocumentSnapshot<Map<String, dynamic>> chat;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final data = chat.data();
    final participants = List<String>.from(data['participants'] as List? ?? const []);
    final otherId = participants.firstWhere((id) => id != currentUserId, orElse: () => currentUserId);
    final names = Map<String, dynamic>.from(data['participantNames'] as Map? ?? const {});
    final name = names[otherId] as String? ?? 'LifeLink user';
    final preview = data['lastMessage'] as String? ?? 'Start a conversation.';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(name: name, recipientId: otherId))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 13, 16, 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 4, offset: Offset(0, 2))]),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: const Color(0xffcf2929), child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Color(0xff101828), fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff52627c), fontSize: 13.5)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.name, required this.recipientId});
  final String name;
  final String recipientId;
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  String get _chatId {
    final myId = FirebaseAuth.instance.currentUser!.uid;
    final ids = [myId, widget.recipientId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null || _sending) return;
    setState(() => _sending = true);
    try {
      await user.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verify your email before sending messages.')));
        return;
      }
      final chat = FirebaseFirestore.instance.collection('chats').doc(_chatId);
      final myName = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : 'LifeLink user';
      await chat.set({
        'participants': [user.uid, widget.recipientId]..sort(),
        'participantNames': {user.uid: myName, widget.recipientId: widget.name},
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await chat.collection('messages').add({
        'senderId': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } on FirebaseException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to send message.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: const Color(0xffcf2929), foregroundColor: Colors.white, title: Text(widget.name)),
    body: Column(children: [
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AsyncStateView.error(error: snapshot.error);
          if (!snapshot.hasData) return const AsyncStateView.loading(label: 'Loading messages...');
          final messages = snapshot.data!.docs;
          if (messages.isEmpty) return AsyncStateView.empty(title: 'Start the conversation', message: 'Send a message to connect with ${widget.name}.', icon: Icons.chat_bubble_outline);
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: messages.length, itemBuilder: (_, index) {
            final message = messages[index].data();
            final mine = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!mine) ...[
                    _Avatar(name: widget.name, radius: 16),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!mine) ...[
                          Text(widget.name, style: const TextStyle(color: Color(0xff71819a), fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                          decoration: BoxDecoration(
                            color: mine ? const Color(0xffd9283b) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: mine ? null : const [BoxShadow(color: Color(0x10000000), blurRadius: 3, offset: Offset(0, 1))],
                          ),
                          child: Text(message['text'] as String? ?? '', style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: _controller, textCapitalization: TextCapitalization.sentences, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Type a message...'))),
        IconButton(icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: Color(0xffd9283b)), onPressed: _sending ? null : _send),
      ]))),
    ]),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.radius = 22});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xffcf2929),
    child: Text(
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: radius * .77),
    ),
  );
}
