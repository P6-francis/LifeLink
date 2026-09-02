import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'messages_screen.dart';
import 'profile_details_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _red = Color(0xffcf2929);
  bool _availableToDonate = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8fa),
        body: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 18, 13, 19),
            color: _red,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PROFILE', style: TextStyle(color: Color(0xffffcaca), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .6)),
              const SizedBox(height: 13),
              const Row(children: [
                CircleAvatar(radius: 29, backgroundColor: Color(0x33ffffff), child: CircleAvatar(radius: 28, backgroundColor: Color(0x33ffffff), child: Text('J', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w600)))),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Juan dela Cruz', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('juan.delacruz@email.com', style: TextStyle(color: Color(0xffffd8d8), fontSize: 11)),
                  SizedBox(height: 5),
                  Row(children: [
                    _HeaderPill(label: 'Blood Type: O+', color: Color(0x33ffffff)),
                    SizedBox(width: 6),
                    _HeaderPill(label: '● Available', color: Color(0xff59aa5b)),
                  ]),
                ])),
              ]),
              const SizedBox(height: 14),
              const Row(children: [Expanded(child: _Stat(number: '12', label: 'Donations')), SizedBox(width: 10), Expanded(child: _Stat(number: '93', label: 'Smart Rank'))]),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 13, 12, 24), children: [
            _sectionLabel('ACCOUNT'),
            const SizedBox(height: 6),
            _group([
              _menu(icon: Icons.lock, title: 'Change Password', onTap: () => _open(const ChangePasswordScreen())),
              _menu(icon: Icons.phone, title: 'Contact Number', onTap: () => _open(const ContactNumberScreen())),
              _menu(icon: Icons.chat_bubble, title: 'Messages', onTap: () => _open(const MessagesScreen())),
            ]),
            const SizedBox(height: 13),
            _sectionLabel('DONOR SETTINGS'),
            const SizedBox(height: 6),
            _group([
              _toggleMenu(icon: Icons.water_drop, title: 'Available to Donate', value: _availableToDonate, onChanged: (value) => setState(() => _availableToDonate = value)),
              _menu(icon: Icons.location_on, title: 'Donation History', onTap: () => _open(const DonationHistoryScreen())),
            ]),
            const SizedBox(height: 13),
            _sectionLabel('PREFERENCES'),
            const SizedBox(height: 6),
            _group([
              _toggleMenu(icon: Icons.notifications, title: 'Push Notifications', value: _pushNotifications, onChanged: (value) => setState(() => _pushNotifications = value)),
              _menu(icon: Icons.info, title: 'About LifeLink', onTap: () => _open(const AboutLifeLinkScreen())),
              _menu(icon: Icons.help, title: 'Help & Support', onTap: () => _open(const HelpSupportScreen())),
            ]),
            const SizedBox(height: 13),
            SizedBox(width: double.infinity, height: 40, child: FilledButton.icon(
              onPressed: () async {
                final shouldLogOut = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 25, 24, 22),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 10))]),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const CircleAvatar(radius: 28, backgroundColor: Color(0xffffe8ec), child: Icon(Icons.logout_rounded, color: _red, size: 27)),
                        const SizedBox(height: 16),
                        const Text('Log out of LifeLink?', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff13223c), fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('You can sign in again anytime to access your account and donor activity.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff6e7e96), fontSize: 14, height: 1.35)),
                        const SizedBox(height: 23),
                        Row(children: [
                          Expanded(child: SizedBox(height: 44, child: OutlinedButton(onPressed: () => Navigator.of(dialogContext).pop(false), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xff52627c), side: const BorderSide(color: Color(0xffdfe3e9)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700))))),
                          const SizedBox(width: 10),
                          Expanded(child: SizedBox(height: 44, child: FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700))))),
                        ]),
                        ]),
                      ),
                    ),
                  ),
                );
                if (shouldLogOut == true && context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (route) => false);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xffffe8ec), foregroundColor: _red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              icon: const Icon(Icons.logout, size: 17),
              label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(height: 15),
            const Center(child: Text('LifeLink v1.0.0 · Built with ♥ for the community', style: TextStyle(color: Color(0xffc2cad6), fontSize: 10))),
          ])),
        ]),
      );

  Widget _sectionLabel(String text) => Padding(padding: const EdgeInsets.only(left: 4), child: Text(text, style: const TextStyle(color: Color(0xff8b9ab2), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .8)));
  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  Widget _group(List<Widget> children) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 4, offset: Offset(0, 2))]), child: Column(children: children));
  Widget _menu({required IconData icon, required String title, required VoidCallback onTap}) => ListTile(visualDensity: const VisualDensity(vertical: -1), onTap: onTap, leading: _icon(icon), title: Text(title, style: const TextStyle(color: Color(0xff13223c), fontSize: 14)), trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xff9aa6b5)));
  Widget _toggleMenu({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) => ListTile(visualDensity: const VisualDensity(vertical: -1), leading: _icon(icon), title: Text(title, style: const TextStyle(color: Color(0xff13223c), fontSize: 14)), trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: _red, inactiveThumbColor: _red, inactiveTrackColor: const Color(0xffffd8dc), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap));
  Widget _icon(IconData icon) => CircleAvatar(radius: 14, backgroundColor: const Color(0xffffe8ec), child: Icon(icon, color: _red, size: 16));
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.number, required this.label});
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) => Container(height: 44, decoration: BoxDecoration(color: const Color(0x33ffffff), borderRadius: BorderRadius.circular(10)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(number, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), Text(label, style: const TextStyle(color: Color(0xffffd6d6), fontSize: 9))]));
}
