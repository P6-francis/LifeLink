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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            itemCount: chats.length + 1,
            separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Inbox', style: TextStyle(color: Color(0xff16233b), fontSize: 24, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Stay connected with donors and requesters.', style: TextStyle(color: Color(0xff71819a), fontSize: 14)),
                ]);
              }
              return _ConversationCard(chat: chats[index - 1], currentUserId: user.uid);
            },
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
    final updatedAt = MessagesScreen._timestamp(data['updatedAt']);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(name: name, recipientId: otherId))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x0d172b4d), blurRadius: 10, offset: Offset(0, 3))]),
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              _Avatar(name: name, radius: 24),
              Positioned(right: -1, bottom: -1, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xff29b473), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff101828), fontSize: 15, fontWeight: FontWeight.w700))), Text(_conversationTime(updatedAt), style: const TextStyle(color: Color(0xff8a99b0), fontSize: 11.5))]),
              const SizedBox(height: 3),
              Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff52627c), fontSize: 13.5)),
            ])),
          ]),
        ),
      ),
    );
  }

  String _conversationTime(DateTime time) {
    if (time.year == 1970) return '';
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) return _clock(time);
    return '${time.month}/${time.day}';
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
  bool _isMuted = false;
  bool _isBlocked = false;

  String get _chatId {
    final myId = FirebaseAuth.instance.currentUser!.uid;
    final ids = [myId, widget.recipientId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  void initState() {
    super.initState();
    _loadConversationSettings();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _loadConversationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final settings = Map<String, dynamic>.from(profile.data()?['messageSettings'] as Map? ?? const {});
      final chatSettings = Map<String, dynamic>.from(settings[_chatId] as Map? ?? const {});
      if (mounted) setState(() {
        _isMuted = chatSettings['muted'] == true;
        _isBlocked = chatSettings['blocked'] == true;
      });
    } on FirebaseException {
      // Messaging itself remains available if personal settings cannot load.
    }
  }

  Future<void> _saveConversationSettings({bool? muted, bool? blocked}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final previousMuted = _isMuted;
    final previousBlocked = _isBlocked;
    final nextMuted = muted ?? _isMuted;
    final nextBlocked = blocked ?? _isBlocked;
    setState(() {
      _isMuted = nextMuted;
      _isBlocked = nextBlocked;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'messageSettings': {
          _chatId: {'muted': nextMuted, 'blocked': nextBlocked},
        },
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isMuted = previousMuted;
        _isBlocked = previousBlocked;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to save conversation settings.')));
    }
  }

  Future<void> _showConversationSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => SafeArea(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xffd9dee7), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              ListTile(leading: _Avatar(name: widget.name, radius: 22), title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Conversation settings')),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                secondary: Icon(_isMuted ? Icons.notifications_off_outlined : Icons.notifications_outlined, color: const Color(0xffcf2929)),
                title: const Text('Mute notifications'),
                subtitle: Text(_isMuted ? 'You will not be notified about new messages.' : 'Get notified about new messages.'),
                value: _isMuted,
                activeColor: const Color(0xffcf2929),
                onChanged: (value) async { await _saveConversationSettings(muted: value); refreshSheet(() {}); },
              ),
              const Divider(),
              ListTile(
                leading: Icon(_isBlocked ? Icons.person_add_alt_1_outlined : Icons.block_outlined, color: _isBlocked ? const Color(0xff249b60) : const Color(0xffcf2929)),
                title: Text(_isBlocked ? 'Unblock contact' : 'Block contact'),
                subtitle: Text(_isBlocked ? 'You can send messages to this contact again.' : 'Hide the composer and stop sending messages in this chat.'),
                onTap: () async {
                  if (!_isBlocked) {
                    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('Block ${widget.name}?'), content: const Text('You will no longer be able to send messages in this conversation.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xffcf2929)), child: const Text('Block'))]));
                    if (confirmed != true) return;
                  }
                  await _saveConversationSettings(blocked: !_isBlocked);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null || _sending || _isBlocked) return;
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
    backgroundColor: const Color(0xfff7f8fa),
    appBar: AppBar(backgroundColor: const Color(0xffcf2929), foregroundColor: Colors.white, elevation: 0, titleSpacing: 0, title: Row(children: [
      CircleAvatar(radius: 17, backgroundColor: Colors.white, child: Text(widget.name.trim().isEmpty ? '?' : widget.name.trim()[0].toUpperCase(), style: const TextStyle(color: Color(0xffcf2929), fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const Text('LifeLink member', style: TextStyle(fontSize: 11.5, color: Color(0xffffdfe2)))])),
    ]), actions: [IconButton(tooltip: 'Conversation settings', icon: const Icon(Icons.more_vert), onPressed: _showConversationSettings)]),
    body: Column(children: [
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AsyncStateView.error(error: snapshot.error);
          if (!snapshot.hasData) return const AsyncStateView.loading(label: 'Loading messages...');
          final messages = snapshot.data!.docs;
          if (messages.isEmpty) return AsyncStateView.empty(title: 'Start the conversation', message: 'Send a message to connect with ${widget.name}.', icon: Icons.chat_bubble_outline);
          return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 18, 16, 12), itemCount: messages.length + 1, itemBuilder: (_, index) {
            if (index == 0) return const Center(child: Padding(padding: EdgeInsets.only(bottom: 18), child: DecoratedBox(decoration: BoxDecoration(color: Color(0xffe9edf3), borderRadius: BorderRadius.all(Radius.circular(20))), child: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Messages are private and secure', style: TextStyle(color: Color(0xff71819a), fontSize: 11))))));
            index -= 1;
            final message = messages[index].data();
            final mine = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
            final createdAt = message['createdAt'] is Timestamp ? (message['createdAt'] as Timestamp).toDate() : null;
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: mine ? const Color(0xffd9283b) : Colors.white,
                            borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18)),
                            boxShadow: mine ? null : const [BoxShadow(color: Color(0x120d1c33), blurRadius: 5, offset: Offset(0, 2))],
                          ),
                          child: Text(message['text'] as String? ?? '', style: TextStyle(color: mine ? Colors.white : const Color(0xff263651), height: 1.35)),
                        ),
                        const SizedBox(height: 3),
                        Text(createdAt == null ? 'Sending...' : _clock(createdAt), style: const TextStyle(color: Color(0xff8a99b0), fontSize: 10.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        },
      )),
      SafeArea(
        child: _isBlocked
            ? Container(width: double.infinity, color: const Color(0xfffff0f1), padding: const EdgeInsets.all(16), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.block_outlined, color: Color(0xffcf2929), size: 18), SizedBox(width: 8), Text('You blocked this contact.', style: TextStyle(color: Color(0xffa22330), fontWeight: FontWeight.w600))]))
            : Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(14, 10, 14, 10), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Container(decoration: BoxDecoration(color: const Color(0xfff1f3f6), borderRadius: BorderRadius.circular(24)), child: TextField(controller: _controller, minLines: 1, maxLines: 4, textCapitalization: TextCapitalization.sentences, textInputAction: TextInputAction.newline, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Write a message', hintStyle: TextStyle(color: Color(0xff8a99b0)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11))))),
                const SizedBox(width: 8),
                Material(color: const Color(0xffcf2929), shape: const CircleBorder(), child: IconButton(tooltip: 'Send message', icon: _sending ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.arrow_upward_rounded, color: Colors.white), onPressed: _sending ? null : _send)),
              ])),
      ),
    ]),
  );
}

String _clock(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
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
