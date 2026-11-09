import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../features/donors/presentation/donor_map_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/messaging/presentation/messages_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/requests/presentation/requests_screen.dart';
import 'lifelink_theme.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/lifelink_header.dart';
import 'tab_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _screens = const [
    HomeScreen(),
    DonorMapScreen(),
    RequestsScreen(),
    _NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    appTabIndex.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appTabIndex,
      builder: (context, index, _) {
        final user = FirebaseAuth.instance.currentUser;
        final unreadStream = user == null
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .snapshots();
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: unreadStream,
          builder: (context, snapshot) {
            final unreadCount =
                snapshot.data?.docs
                    .where((doc) => doc.data()['read'] != true)
                    .length ??
                0;
            return Scaffold(
              body: SafeArea(child: _screens[index]),
              bottomNavigationBar: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (value) => appTabIndex.value = value,
                backgroundColor: Colors.white,
                indicatorColor: LifeLinkColors.redSoft,
                elevation: 0,
                height: 68,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Feed',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.search_rounded),
                    label: 'Find Donors',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment_rounded),
                    label: 'My Requests',
                  ),
                  NavigationDestination(
                    icon: _notificationNavIcon(
                      Icons.notifications_none,
                      unreadCount,
                    ),
                    selectedIcon: _notificationNavIcon(
                      Icons.notifications,
                      unreadCount,
                    ),
                    label: 'Notifications',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _notificationNavIcon(IconData icon, int unreadCount) {
    if (unreadCount == 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -10,
          top: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xffcf2929),
              shape: BoxShape.circle,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationsScreen extends StatefulWidget {
  const _NotificationsScreen();

  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  static const _red = Color(0xffcf2929);
  bool _markingRead = false;
  bool _deletingSelected = false;
  bool _selectionMode = false;
  final Set<String> _selectedNotificationIds = {};

  Future<void> _markAllRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    final unread = notifications.where((doc) => doc.data()['read'] != true);
    if (unread.isEmpty || _markingRead) return;
    setState(() => _markingRead = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final notification in unread) {
        batch.update(notification.reference, {'read': true});
      }
      await batch.commit();
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _deleteSelected(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    final selected = notifications.where(
      (doc) => _selectedNotificationIds.contains(doc.id),
    );
    if (selected.isEmpty || _deletingSelected) return;
    setState(() => _deletingSelected = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final notification in selected) {
        batch.delete(notification.reference);
      }
      await batch.commit();
    } finally {
      if (mounted) {
        setState(() {
          _deletingSelected = false;
          _selectedNotificationIds.clear();
          _selectionMode = false;
        });
      }
    }
  }

  Future<void> _openNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    if (_selectionMode) {
      setState(() {
        if (!_selectedNotificationIds.add(notification.id)) {
          _selectedNotificationIds.remove(notification.id);
        }
      });
      return;
    }
    final data = notification.data();
    if (data['read'] != true)
      await notification.reference.update({'read': true});
    if (!mounted || data['type'] != 'chat') return;
    final senderId = (data['senderId'] as String?)?.trim() ?? '';
    if (senderId.isEmpty) return;
    final senderName = (data['senderName'] as String?)?.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          recipientId: senderId,
          name: senderName?.isNotEmpty == true ? senderName! : 'LifeLink user',
        ),
      ),
    );
  }

  String _notificationSource(Map<String, dynamic> data) {
    final type = ((data['type'] ?? data['source']) as String? ?? '')
        .toLowerCase();
    if (type == 'chat' || type == 'message') return 'Message';
    if (type.contains('request')) return 'Request update';
    if (type.contains('donor') || type.contains('donation'))
      return 'Donor update';
    return 'LifeLink update';
  }

  IconData _notificationSourceIcon(Map<String, dynamic> data) {
    final type = ((data['type'] ?? data['source']) as String? ?? '')
        .toLowerCase();
    if (type == 'chat' || type == 'message') return Icons.chat_bubble_outline;
    if (type.contains('request')) return Icons.assignment_outlined;
    if (type.contains('donor') || type.contains('donation'))
      return Icons.volunteer_activism_outlined;
    return Icons.notifications_none;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(
        body: Center(child: Text('Please sign in to view notifications.')),
      );
    final notifications = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
    return Scaffold(
      backgroundColor: LifeLinkColors.canvas,
      body: Column(
        children: [
          LifeLinkHeader(
            title: lifeLinkHeaderTitle('Notifications'),
            onMessagesPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesScreen()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: notifications,
              builder: (context, snapshot) {
                final items = snapshot.data?.docs ?? [];
                final itemIds = items.map((item) => item.id).toSet();
                _selectedNotificationIds.removeWhere(
                  (id) => !itemIds.contains(id),
                );
                final unreadCount = items
                    .where((item) => item.data()['read'] != true)
                    .length;
                final allSelected =
                    items.isNotEmpty &&
                    _selectedNotificationIds.length == items.length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: LifeLinkColors.border),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.notifications,
                                      size: 21,
                                      color: _red,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Notifications',
                                          style: TextStyle(
                                            color: _red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Read updates from requests, donors, and\nsupport messages.',
                                          style: TextStyle(
                                            color: Color(0xff62738d),
                                            fontSize: 14,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: _red,
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Unread notifications',
                                    style: TextStyle(
                                      color: Color(0xff73839b),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Divider(
                                height: 1,
                                color: Color(0xffedf0f3),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _markingRead || unreadCount == 0
                                        ? null
                                        : () => _markAllRead(items),
                                    icon: _markingRead
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.done_all, size: 17),
                                    label: const Text(
                                      'Mark all as read',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!_selectionMode)
                                    TextButton.icon(
                                      onPressed: items.isEmpty
                                          ? null
                                          : () => setState(() {
                                              _selectionMode = true;
                                              _selectedNotificationIds.clear();
                                            }),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    TextButton.icon(
                                      onPressed: () => setState(() {
                                        if (allSelected) {
                                          _selectedNotificationIds.clear();
                                        } else {
                                          _selectedNotificationIds
                                            ..clear()
                                            ..addAll(itemIds);
                                        }
                                      }),
                                      icon: Icon(
                                        allSelected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        size: 17,
                                      ),
                                      label: Text(
                                        allSelected
                                            ? 'Clear all'
                                            : 'Select all',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          _selectedNotificationIds.isEmpty ||
                                              _deletingSelected
                                          ? null
                                          : () => _deleteSelected(items),
                                      icon: _deletingSelected
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.delete_outline,
                                              size: 17,
                                            ),
                                      label: Text(
                                        'Delete (${_selectedNotificationIds.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Cancel selection',
                                      onPressed: () => setState(() {
                                        _selectionMode = false;
                                        _selectedNotificationIds.clear();
                                      }),
                                      icon: const Icon(Icons.close, size: 18),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xffedf0f3)),
                        Expanded(
                          child: items.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        size: 36,
                                        color: Color(0xffb1bac8),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'No notifications yet',
                                        style: TextStyle(
                                          color: Color(0xff71819a),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'New updates will appear here automatically.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xff98a4b6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    14,
                                    12,
                                    14,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final notification = items[index];
                                    final data = notification.data();
                                    final read = data['read'] == true;
                                    final timestamp =
                                        data['createdAt'] as Timestamp?;
                                    final when = timestamp == null
                                        ? 'Just now'
                                        : _dateTimeLabel(timestamp.toDate());
                                    final selected = _selectedNotificationIds
                                        .contains(notification.id);
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Material(
                                        color: selected
                                            ? const Color(0xfff7f8fa)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () =>
                                              _openNotification(notification),
                                          child: Padding(
                                            padding: const EdgeInsets.all(15),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (_selectionMode) ...[
                                                  Checkbox(
                                                    value: selected,
                                                    activeColor: _red,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    onChanged: (_) => setState(() {
                                                      if (!_selectedNotificationIds
                                                          .add(
                                                            notification.id,
                                                          )) {
                                                        _selectedNotificationIds
                                                            .remove(
                                                              notification.id,
                                                            );
                                                      }
                                                    }),
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                _notificationAvatar(data),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        (data['title']
                                                                as String?) ??
                                                            'LifeLink',
                                                        style: TextStyle(
                                                          fontWeight: read
                                                              ? FontWeight.w600
                                                              : FontWeight.w800,
                                                          color: const Color(
                                                            0xff1c2b42,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        (data['body']
                                                                as String?) ??
                                                            '',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xff62738d,
                                                          ),
                                                          height: 1.25,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            _notificationSourceIcon(
                                                              data,
                                                            ),
                                                            size: 13,
                                                            color: _red,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            _notificationSource(
                                                              data,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  color: _red,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        when,
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xff99a6b8,
                                                          ),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (!read)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 8,
                                                      top: 4,
                                                    ),
                                                    child: CircleAvatar(
                                                      radius: 4,
                                                      backgroundColor: _red,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  static String _dateTimeLabel(DateTime time) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${months[time.month - 1]} ${time.day}, ${time.year} · $hour:$minute $period';
  }

  Widget _notificationAvatar(Map<String, dynamic> data) {
    final userId = ((data['senderId'] ?? data['donorId']) as String?)?.trim();
    if (userId?.isNotEmpty != true) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(_notificationSourceIcon(data), color: _red),
      );
    }

    final name =
        ((data['senderName'] ?? data['donorName'] ?? data['title']) as String?)
            ?.trim();
    return ProfileAvatar(
      name: name?.isNotEmpty == true ? name! : 'LifeLink',
      userId: userId,
      imageUrl: data['avatarUrl'] as String?,
      radius: 20,
    );
  }
}
