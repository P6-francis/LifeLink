import 'package:flutter/material.dart';

import '../app/tab_navigation.dart';
import 'active_requests_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const _red = Color(0xffcf2929);

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(color: _red),
          child: Row(children: [
            const CircleAvatar(radius: 22, backgroundColor: Color(0x30ffffff), child: Icon(Icons.favorite_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Good day', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('Every donation can save a life.', style: TextStyle(color: Color(0xffffe7e9), fontSize: 12.5)),
            ])),
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0x30ffffff), shape: BoxShape.circle), child: IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesScreen())), icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20), tooltip: 'Messages')),
          ]),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LIFE-SAVING NETWORK', style: TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 7),
            const Text('Welcome to LifeLink', style: TextStyle(color: Color(0xff111d31), fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('Connect with donors, find urgent requests,\nand help save lives in your community.', style: TextStyle(color: Color(0xff52627c), fontSize: 13, height: 1.35)),
            const SizedBox(height: 11),
            const Wrap(spacing: 8, runSpacing: 6, children: [_Tag('Fast Matching'), _Tag('Verified Donors'), _Tag('Local Support')]),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity, height: 41, child: FilledButton.icon(onPressed: () => appTabIndex.value = 1, style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.group, size: 17), label: const Text('Browse Available Donors', style: TextStyle(fontWeight: FontWeight.w700)))),
            const SizedBox(height: 7),
            SizedBox(width: double.infinity, height: 41, child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActiveRequestsScreen())), style: OutlinedButton.styleFrom(foregroundColor: _red, side: const BorderSide(color: _red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), icon: const Icon(Icons.water_drop, size: 17), label: const Text('View Active Requests', style: TextStyle(fontWeight: FontWeight.w700)))),
          ])),
          const SizedBox(height: 10),
          _card(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What You Can Do With LifeLink', style: TextStyle(color: Color(0xff263651), fontSize: 14, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            _Feature(text: 'Search and match with nearby available\ndonors by blood type.'),
            _Feature(text: 'Create urgent blood requests with pinned\nmap location.'),
            _Feature(text: 'Contact donors and support via chat,\ncall, and SMS.'),
            _Feature(text: 'Track request status and manage your\ndonor profile.'),
          ])),
          const SizedBox(height: 10),
          const Row(children: [Expanded(child: _Stat(number: '24/7', label: 'Request Visibility')), SizedBox(width: 10), Expanded(child: _Stat(number: '1 App', label: 'For Donors & Requests'))]),
          const SizedBox(height: 10),
          const Row(children: [Expanded(child: _Stat(number: 'Fast', label: 'Donor Matching')), SizedBox(width: 10), Expanded(child: _Stat(number: '100%', label: 'Community Driven'))]),
        ])),
      ]);

  static Widget _card({required Widget child}) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2))]), child: child);
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4), decoration: BoxDecoration(color: const Color(0xffffe7eb), border: Border.all(color: const Color(0xffffbbc2)), borderRadius: BorderRadius.circular(14)), child: Text(text, style: const TextStyle(color: Color(0xffcf2929), fontSize: 11)));
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.circle, color: Color(0xffcf2929), size: 13)), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Color(0xff52627c), fontSize: 13, height: 1.25)))]));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.number, required this.label});
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(number, style: const TextStyle(color: Color(0xffcf2929), fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: Color(0xff61708a), fontSize: 10))]));
}
