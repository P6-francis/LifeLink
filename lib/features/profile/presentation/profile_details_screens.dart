import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _red = Color(0xffcf2929);
const _pageBg = Color(0xfff7f8fa);

AppBar _appBar(BuildContext context, String title) => AppBar(
      backgroundColor: _red,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 4,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
      ),
    );

Widget _page({required String title, required Widget child}) => Builder(
      builder: (context) => Scaffold(
        backgroundColor: _pageBg,
        appBar: _appBar(context, title),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [child],
        ),
      ),
    );

Widget _card(Widget child) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: child,
    );

Widget _label(String value) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        value,
        style: const TextStyle(color: Color(0xff13223c), fontSize: 16),
      ),
    );

Widget _input(
  TextEditingController controller,
  String hint, {
  bool obscureText = false,
  Widget? suffix,
  TextInputType? keyboardType,
}) =>
    SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffdfe3e9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red),
          ),
        ),
      ),
    );

Widget _primaryButton(String text, VoidCallback onPressed) => SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

class EditInformationScreen extends StatefulWidget {
  const EditInformationScreen({super.key});

  @override
  State<EditInformationScreen> createState() => _EditInformationScreenState();
}

class _EditInformationScreenState extends State<EditInformationScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _barangay = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snapshot.data()?['userInformation'] as Map<String, dynamic>? ?? {};
    _name.text = data['fullName'] as String? ?? user.displayName ?? '';
    _phone.text = data['phone'] as String? ?? '';
    _barangay.text = data['barangay'] as String? ?? '';
    _city.text = data['city'] as String? ?? '';
    _province.text = data['province'] as String? ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if ([_name, _phone, _barangay, _city, _province].any((field) => field.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all information fields.')));
      return;
    }
    if (_phone.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact number must contain 11 digits.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final city = _city.text.trim();
      final address = '${_barangay.text.trim()}, $city, ${_province.text.trim()}';
      final userDocument = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await user.updateDisplayName(name);
      await userDocument.set({
        'userInformation': {
          'fullName': name,
          'phone': _phone.text.trim(),
          'barangay': _barangay.text.trim(),
          'city': city,
          'province': _province.text.trim(),
          'address': address,
        },
      }, SetOptions(merge: true));
      final profile = await userDocument.get();
      final info = profile.data()?['userInformation'] as Map<String, dynamic>? ?? {};
      await FirebaseFirestore.instance.collection('donors').doc(user.uid).set({
        'name': name,
        'bloodType': info['bloodType'] as String? ?? '',
        'city': city,
        'isAvailable': (info['bloodType'] as String? ?? '').isNotEmpty,
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Information updated.')));
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Unable to update information.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _barangay, _city, _province]) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _page(
    title: 'Edit Information',
    child: _loading
        ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _red)))
        : _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            _label('Full Name'), _input(_name, 'Enter your full name'),
            const SizedBox(height: 14),
            _label('Contact Number'), _input(_phone, '09xx xxx xxxx', keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _label('Barangay'), _input(_barangay, 'Enter barangay'),
            const SizedBox(height: 14),
            _label('City / Municipality'), _input(_city, 'Enter city or municipality'),
            const SizedBox(height: 14),
            _label('Province'), _input(_province, 'Enter province'),
            const SizedBox(height: 24),
            _primaryButton(_saving ? 'Saving...' : 'Save Changes', _saving ? () {} : _save),
          ])),
  );
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final currentPassword = _current.text;
    final newPassword = _next.text;
    final confirmedPassword = _confirm.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmedPassword.isEmpty) {
      _showMessage('Please complete all password fields.');
      return;
    }
    if (newPassword.length < 6) {
      _showMessage('Your new password must have at least 6 characters.');
      return;
    }
    if (newPassword != confirmedPassword) {
      _showMessage('New passwords do not match.');
      return;
    }
    if (currentPassword == newPassword) {
      _showMessage('Your new password must be different from the current password.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      _showMessage('Please sign in again before changing your password.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
      await user.updatePassword(newPassword);
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _confirm.clear();
      _showMessage('Password updated successfully.');
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'wrong-password' || 'invalid-credential' => 'Your current password is incorrect.',
        'weak-password' => 'Choose a stronger password.',
        'requires-recent-login' => 'Please sign in again, then try changing your password.',
        _ => error.message ?? 'Unable to update your password.',
      };
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => _page(
        title: 'Change Password',
        child: _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Current Password'),
              _password(
                _current,
                'Enter current password',
                _obscureCurrent,
                () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 17),
              _label('New Password'),
              _password(
                _next,
                'Enter new password',
                _obscureNext,
                () => setState(() => _obscureNext = !_obscureNext),
              ),
              const SizedBox(height: 17),
              _label('Confirm New Password'),
              _password(
                _confirm,
                'Re-enter new password',
                _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 20),
              _primaryButton(
                _isSaving ? 'Updating...' : 'Update Password',
                _isSaving ? () {} : _updatePassword,
              ),
            ],
          ),
        ),
      );

  Widget _password(
    TextEditingController controller,
    String hint,
    bool obscure,
    VoidCallback onToggle,
  ) =>
      _input(
        controller,
        hint,
        obscureText: obscure,
        suffix: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: _red,
            size: 20,
          ),
        ),
      );
}

class ContactNumberScreen extends StatefulWidget {
  const ContactNumberScreen({super.key});

  @override
  State<ContactNumberScreen> createState() => _ContactNumberScreenState();
}

class _ContactNumberScreenState extends State<ContactNumberScreen> {
  final _number = TextEditingController(text: '09123456789');

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _page(
        title: 'Contact Number',
        child: _card(
          Column(
            children: [
              const SizedBox(height: 15),
              const CircleAvatar(
                radius: 31,
                backgroundColor: Color(0xffffe8ec),
                child: Icon(Icons.phone, color: _red, size: 27),
              ),
              const SizedBox(height: 17),
              const Text(
                'This number is used to contact you when a donor\nresponds to your request.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff62738d), fontSize: 14),
              ),
              const SizedBox(height: 31),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phone Number',
                  style: TextStyle(color: Color(0xff13223c), fontSize: 16),
                ),
              ),
              const SizedBox(height: 7),
              _input(_number, '09123456789',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _primaryButton(
                'Save Number',
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact number saved.')),
                ),
              ),
            ],
          ),
        ),
      );
}

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => _page(
        title: 'Donation History',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              const Row(
                children: [
                  Expanded(child: _HistoryStat('4', 'Total Donations')),
                  SizedBox(width: 10),
                  Expanded(child: _HistoryStat('O+', 'Blood Type')),
                  SizedBox(width: 10),
                  Expanded(child: _HistoryStat('93', 'Smart Rank')),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'ALL DONATIONS',
              style: TextStyle(
                color: Color(0xff8b9ab2),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 8),
            const _DonationCard(
                'LMMC, San Fernando', 'Jul 14, 2025', 'Maria S.'),
            const SizedBox(height: 9),
            const _DonationCard(
                'Ilocos Sur Provincial', 'Apr 2, 2025', 'Roberto C.'),
            const SizedBox(height: 9),
            const _DonationCard(
                'Bacnotan District Hospital', 'Jan 18, 2025', 'Anna R.'),
            const SizedBox(height: 9),
            const _DonationCard(
                'LMMC, San Fernando', 'Oct 5, 2024', 'Pedro L.'),
          ],
        ),
      );
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat(this.number, this.label);
  final String number, label;

  @override
  Widget build(BuildContext context) => Container(
        height: 66,
        decoration: BoxDecoration(
          color: const Color(0xffffe8ec),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(
                color: _red,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xff62738d), fontSize: 11),
            ),
          ],
        ),
      );
}

class _DonationCard extends StatelessWidget {
  const _DonationCard(this.hospital, this.date, this.recipient);
  final String hospital, date, recipient;

  @override
  Widget build(BuildContext context) => _card(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(date, style: const TextStyle(color: Color(0xff72829a))),
                  Text(
                    'Recipient: $recipient',
                    style: const TextStyle(color: Color(0xff72829a)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badge('O+', const Color(0xffffe8ec), _red),
                const SizedBox(height: 6),
                _badge('Completed', const Color(0xffe6f4e7),
                    const Color(0xff20913a)),
              ],
            ),
          ],
        ),
      );

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
}

class AboutLifeLinkScreen extends StatelessWidget {
  const AboutLifeLinkScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _pageBg,
        body: Column(
          children: [
            Container(
              // Keep the hero compact on physical devices while retaining
              // enough room for all its fixed content.
              height: 205,
              width: double.infinity,
              color: _red,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Text(
                          'About LifeLink',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0x33ffffff),
                      border: Border.all(
                          color: const Color(0x77ffffff), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.water_drop,
                        size: 30, color: Color(0xffe33135)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'LifeLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Life-Saving Network · v1.0.0',
                    style: TextStyle(color: Color(0xffffd5d5), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _infoCard(
                    'Our Mission',
                    const Text(
                      'LifeLink connects blood donors with people in urgent need, making it faster and easier to find life-saving blood in your community — without relying on social media posts.',
                      style: TextStyle(
                        color: Color(0xff435a7b),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    'Key Features',
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Feature(
                          '🔎',
                          'Smart Donor Matching',
                          'Find nearby donors ranked by compatibility\nand availability.',
                        ),
                        _Feature(
                          '📍',
                          'Map-Pinned Requests',
                          'Create requests with a precise location for\nfaster response.',
                        ),
                        _Feature(
                          '💬',
                          'Built-in Messaging',
                          'Chat directly with donors without sharing\npersonal numbers.',
                        ),
                        _Feature(
                          '🔔',
                          'Real-time Notifications',
                          'Get instant alerts when a donor accepts your\nrequest.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    'Built With Love',
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LifeLink was built over 4 months by a passionate team dedicated to saving lives through technology. Every feature was designed with donors and recipients in mind.',
                          style:
                              TextStyle(color: Color(0xff62738d), height: 1.4),
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            '© 2025 LifeLink. All rights reserved.',
                            style: TextStyle(
                              color: Color(0xff8a99b0),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _infoCard(String title, Widget child) => _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.body);
  final String icon, title, body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 19)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xff62738d),
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _pageBg,
        appBar: _appBar(context, 'Help & Support'),
        body: Column(
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                'How do I find a donor?',
                'How to create a request?',
                'What is Smart Rank?',
                'How do I message someone?'
              ]
                  .map(
                    (text) => ActionChip(
                      label: Text(text),
                      labelStyle:
                          const TextStyle(color: _red, fontSize: 13),
                      backgroundColor: const Color(0xfffff0f1),
                      side: const BorderSide(color: Color(0xffffc9ce)),
                      onPressed: () => _message.text = text,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 14, backgroundColor: _red),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 3,
                          )
                        ],
                      ),
                      child: const Text(
                        "Hi! I'm the LifeLink Assistant 🩸. How can I help you today? You can ask me about finding donors, creating requests, your account, and more.",
                        style: TextStyle(fontSize: 16, height: 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything about LifeLink...',
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: Color(0xffdfe3e9)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _red,
                      child: IconButton(
                        onPressed: () => _message.clear(),
                        icon:
                            const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
