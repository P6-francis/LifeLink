import 'package:flutter/material.dart';

const _red = Color(0xffcf2929);
const _pageBg = Color(0xfff7f8fa);

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController(), _next = TextEditingController(), _confirm = TextEditingController();
  bool _obscure = true;
  @override void dispose() { _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => _Page(title: 'Change Password', child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _label('Current Password'), _password(_current, 'Enter current password'), const SizedBox(height: 17),
    _label('New Password'), _password(_next, 'Enter new password'), const SizedBox(height: 17),
    _label('Confirm New Password'), _password(_confirm, 'Re-enter new password'), const SizedBox(height: 20),
    _primaryButton('Update Password', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')))),
  ])));
  Widget _password(TextEditingController controller, String hint) => _input(controller, hint, obscureText: _obscure, suffix: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: _red, size: 20)));
}

class ContactNumberScreen extends StatefulWidget {
  const ContactNumberScreen({super.key});
  @override State<ContactNumberScreen> createState() => _ContactNumberScreenState();
}
class _ContactNumberScreenState extends State<ContactNumberScreen> {
  final _number = TextEditingController(text: '09123456789');
  @override void dispose() { _number.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => _Page(title: 'Contact Number', child: _card(Column(children: [
    const SizedBox(height: 15), const CircleAvatar(radius: 31, backgroundColor: Color(0xffffe8ec), child: Icon(Icons.phone, color: _red, size: 27)),
    const SizedBox(height: 17), const Text('This number is used to contact you when a donor\nresponds to your request.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff62738d), fontSize: 14)),
    const SizedBox(height: 31), const Align(alignment: Alignment.centerLeft, child: Text('Phone Number', style: TextStyle(color: Color(0xff13223c), fontSize: 16))), const SizedBox(height: 7),
    _input(_number, '09123456789', keyboardType: TextInputType.phone), const SizedBox(height: 16), _primaryButton('Save Number', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact number saved.')))),
  ])));
}

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});
  @override Widget build(BuildContext context) => _Page(title: 'Donation History', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _card(Row(children: const [Expanded(child: _HistoryStat('4', 'Total Donations')), SizedBox(width: 10), Expanded(child: _HistoryStat('O+', 'Blood Type')), SizedBox(width: 10), Expanded(child: _HistoryStat('93', 'Smart Rank'))])),
    const SizedBox(height: 15), const Text('ALL DONATIONS', style: TextStyle(color: Color(0xff8b9ab2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8)), const SizedBox(height: 8),
    const _DonationCard('LMMC, San Fernando', 'Jul 14, 2025', 'Maria S.'), const SizedBox(height: 9), const _DonationCard('Ilocos Sur Provincial', 'Apr 2, 2025', 'Roberto C.'), const SizedBox(height: 9), const _DonationCard('Bacnotan District Hospital', 'Jan 18, 2025', 'Anna R.'), const SizedBox(height: 9), const _DonationCard('LMMC, San Fernando', 'Oct 5, 2024', 'Pedro L.'),
  ]));
}

class AboutLifeLinkScreen extends StatelessWidget {
  const AboutLifeLinkScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: _pageBg, body: Column(children: [
    Container(height: 230, width: double.infinity, color: _red, child: Column(children: [
      Padding(padding: const EdgeInsets.only(top: 10, left: 5), child: Row(children: [IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, color: Colors.white)), const Text('About LifeLink', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))])),
      const Spacer(), Container(width: 78, height: 78, decoration: BoxDecoration(color: const Color(0x33ffffff), border: Border.all(color: const Color(0x77ffffff), width: 2), borderRadius: BorderRadius.circular(23)), child: const Icon(Icons.water_drop, size: 39, color: Color(0xffe33135))), const SizedBox(height: 10), const Text('LifeLink', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('Life-Saving Network · v1.0.0', style: TextStyle(color: Color(0xffffd5d5), fontSize: 13)), const SizedBox(height: 29),
    ])),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
      _infoCard('Our Mission', const Text('LifeLink connects blood donors with people in urgent need, making it faster and easier to find life-saving blood in your community — without relying on social media posts.', style: TextStyle(color: Color(0xff435a7b), fontSize: 16, height: 1.5))),
      const SizedBox(height: 12), _infoCard('Key Features', const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Feature('🔎', 'Smart Donor Matching', 'Find nearby donors ranked by compatibility\nand availability.'), _Feature('📍', 'Map-Pinned Requests', 'Create requests with a precise location for\nfaster response.'), _Feature('💬', 'Built-in Messaging', 'Chat directly with donors without sharing\npersonal numbers.'), _Feature('🔔', 'Real-time Notifications', 'Get instant alerts when a donor accepts your\nrequest.'),
      ])), const SizedBox(height: 12), _infoCard('Built With Love', const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LifeLink was built over 4 months by a passionate team dedicated to saving lives through technology. Every feature was designed with donors and recipients in mind.', style: TextStyle(color: Color(0xff62738d), height: 1.4)), SizedBox(height: 15), Center(child: Text('© 2025 LifeLink. All rights reserved.', style: TextStyle(color: Color(0xff8a99b0), fontSize: 12)))])),
    ])),
  ]));
}

class HelpSupportScreen extends StatefulWidget { const HelpSupportScreen({super.key}); @override State<HelpSupportScreen> createState() => _HelpSupportScreenState(); }
class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _message = TextEditingController();
  @override void dispose() { _message.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: _pageBg, appBar: _appBar(context, 'Help & Support'), body: Column(children: [
    Wrap(spacing: 7, runSpacing: 7, children: ['How do I find a donor?', 'How to create a request?', 'What is Smart Rank?', 'How do I message someone?'].map((text) => ActionChip(label: Text(text), labelStyle: const TextStyle(color: _red, fontSize: 13), backgroundColor: const Color(0xfffff0f1), side: const BorderSide(color: Color(0xffffc9ce)), onPressed: () => _message.text = text)).toList()),
    const SizedBox(height: 15), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircleAvatar(radius: 14, backgroundColor: _red), const SizedBox(width: 9), Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 3)]), child: const Text("Hi! I'm the LifeLink Assistant 🩸. How can I help you today? You can ask me about finding donors, creating requests, your account, and more.", style: TextStyle(fontSize: 16, height: 1.2))))])),
    const Spacer(), SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), child: Row(children: [Expanded(child: TextField(controller: _message, decoration: InputDecoration(hintText: 'Ask me anything about LifeLink...', contentPadding: const EdgeInsets.symmetric(horizontal: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xffdfe3e9))))),), const SizedBox(width: 8), CircleAvatar(radius: 20, backgroundColor: _red, child: IconButton(onPressed: () => _message.clear(), icon: const Icon(Icons.send, color: Colors.white, size: 20)))]))),
  ]));
}

class _Page extends StatelessWidget { const _Page({required this.title, required this.child}); final String title; final Widget child; @override Widget build(BuildContext context) => Scaffold(backgroundColor: _pageBg, appBar: _appBar(context, title), body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [child])); }
AppBar _appBar(BuildContext context, String title) => AppBar(backgroundColor: _red, foregroundColor: Colors.white, elevation: 0, titleSpacing: 4, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)));
Widget _card(Widget child) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]), child: child);
Widget _label(String value) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(value, style: const TextStyle(color: Color(0xff13223c), fontSize: 16)));
Widget _input(TextEditingController controller, String hint, {bool obscureText = false, Widget? suffix, TextInputType? keyboardType}) => SizedBox(height: 46, child: TextField(controller: controller, obscureText: obscureText, keyboardType: keyboardType, decoration: InputDecoration(hintText: hint, suffixIcon: suffix, contentPadding: const EdgeInsets.symmetric(horizontal: 15), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffdfe3e9))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red)))));
Widget _primaryButton(String text, VoidCallback onPressed) => SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))));
Widget _infoCard(String title, Widget child) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 12), child]));
class _HistoryStat extends StatelessWidget { const _HistoryStat(this.number, this.label); final String number, label; @override Widget build(BuildContext context) => Container(height: 66, decoration: BoxDecoration(color: const Color(0xffffe8ec), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(number, style: const TextStyle(color: _red, fontWeight: FontWeight.w700, fontSize: 19)), Text(label, style: const TextStyle(color: Color(0xff62738d), fontSize: 11))])); }
class _DonationCard extends StatelessWidget { const _DonationCard(this.hospital, this.date, this.recipient); final String hospital, date, recipient; @override Widget build(BuildContext context) => _card(Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hospital, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), Text(date, style: const TextStyle(color: Color(0xff72829a))), Text('Recipient: $recipient', style: const TextStyle(color: Color(0xff72829a)))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_badge('O+', const Color(0xffffe8ec), _red), const SizedBox(height: 6), _badge('Completed', const Color(0xffe6f4e7), const Color(0xff20913a))]) ])); }
Widget _badge(String text, Color bg, Color fg) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)));
class _Feature extends StatelessWidget { const _Feature(this.icon, this.title, this.body); final String icon, title, body; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(icon, style: const TextStyle(fontSize: 19)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), Text(body, style: const TextStyle(color: Color(0xff62738d), fontSize: 13, height: 1.2))]))])); }
