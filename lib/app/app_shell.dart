import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/donor_map_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/requests_screen.dart';
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
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appTabIndex,
      builder: (context, index, _) => Scaffold(
        body: SafeArea(child: _screens[index]),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: index,
          onTap: (value) => appTabIndex.value = value,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xffcf2929),
          unselectedItemColor: const Color(0xff9aa0a9),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Feed'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find Donors'),
            BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted), label: 'My Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications), label: 'Notifications'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  static const _red = Color(0xffcf2929);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        body: Column(children: [
          Container(
            height: 53,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xffedf0f3)))),
            child: const Text('Notifications', style: TextStyle(color: Color(0xff13223c), fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 18, backgroundColor: Color(0xffffe8ec), child: Icon(Icons.notifications, size: 21, color: _red)),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Notifications', style: TextStyle(color: _red, fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 3),
                    Text('Read updates from requests, donors, and\nsupport messages.', style: TextStyle(color: Color(0xff62738d), fontSize: 14, height: 1.25)),
                  ])),
                ]),
                const SizedBox(height: 15),
                const Row(children: [
                  CircleAvatar(radius: 10, backgroundColor: _red, child: Text('0', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                  SizedBox(width: 10),
                  Text('Unread notifications', style: TextStyle(color: Color(0xff73839b), fontSize: 14)),
                ]),
                const SizedBox(height: 15),
                const Divider(height: 1, color: Color(0xffedf0f3)),
                const SizedBox(height: 5),
                Row(children: [
                  TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications are marked as read.'))), style: TextButton.styleFrom(foregroundColor: _red, padding: const EdgeInsets.symmetric(horizontal: 0)), child: const Text('Mark all as read', style: TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(width: 16),
                  TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Read notifications deleted.'))), style: TextButton.styleFrom(foregroundColor: _red, padding: EdgeInsets.zero), child: const Text('Delete read', style: TextStyle(fontWeight: FontWeight.w600))),
                ]),
              ]),
            ),
            const SizedBox(height: 26),
            const Center(child: Text('No notifications', style: TextStyle(color: Color(0xff8a99b0), fontSize: 15))),
          ])),
        ]),
      );
}
