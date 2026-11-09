import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/lifelink_theme.dart';
import '../../../app/tab_navigation.dart';
import '../../../services/location_geocoding_service.dart';
import '../../../widgets/password_requirements.dart';

const _red = LifeLinkColors.red;
const _pageBg = LifeLinkColors.canvas;

AppBar _appBar(BuildContext context, String title) => AppBar(
  centerTitle: false,
  title: Text(title),
  leading: IconButton(
    onPressed: () => Navigator.of(context).pop(),
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
  ),
);

Widget _page({
  required String title,
  required String subtitle,
  required IconData icon,
  required Widget child,
}) => Builder(
  builder: (context) => Scaffold(
    backgroundColor: _pageBg,
    appBar: _appBar(context, title),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, LifeLinkColors.redSoft],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xffffd6d6)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: _red, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: LifeLinkColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LifeLinkColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  ),
);

Widget _card(Widget child) => Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: LifeLinkColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x0a17233b), blurRadius: 18, offset: Offset(0, 7)),
    ],
  ),
  child: child,
);

Widget _label(String value) => Padding(
  padding: const EdgeInsets.only(bottom: 7),
  child: Text(
    value,
    style: const TextStyle(
      color: LifeLinkColors.ink,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  ),
);

Widget _input(
  TextEditingController controller,
  String hint, {
  bool obscureText = false,
  Widget? suffix,
  Widget? prefix,
  TextInputType? keyboardType,
  ValueChanged<String>? onChanged,
}) => SizedBox(
  height: 50,
  child: TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      filled: true,
      fillColor: LifeLinkColors.canvas,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: LifeLinkColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _red, width: 1.5),
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
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  ),
);

class EditInformationScreen extends StatefulWidget {
  const EditInformationScreen({super.key});

  @override
  State<EditInformationScreen> createState() => _EditInformationScreenState();
}

class _AssistantMessage {
  const _AssistantMessage({
    required this.text,
    required this.isUser,
    this.actionLabel,
    this.targetTab,
  });
  final String text;
  final bool isUser;
  final String? actionLabel;
  final int? targetTab;

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    if (actionLabel != null) 'actionLabel': actionLabel,
    if (targetTab != null) 'targetTab': targetTab,
  };

  factory _AssistantMessage.fromJson(Map<String, dynamic> json) =>
      _AssistantMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        actionLabel: json['actionLabel'] as String?,
        targetTab: json['targetTab'] as int?,
      );
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message, required this.onOpenTab});
  final _AssistantMessage message;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 305),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: message.isUser ? _red : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: message.isUser
            ? null
            : const [BoxShadow(color: Color(0x11000000), blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: message.isUser ? Colors.white : const Color(0xff263651),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          if (message.targetTab != null)
            TextButton.icon(
              onPressed: () => onOpenTab(message.targetTab!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(message.actionLabel ?? 'Open feature'),
              style: TextButton.styleFrom(
                foregroundColor: message.isUser ? Colors.white : _red,
                padding: const EdgeInsets.only(top: 7),
              ),
            ),
        ],
      ),
    );

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: bubble,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: _red,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset('assets/lifelink_logo.svg'),
          ),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _AssistantReply {
  const _AssistantReply(this.text, {this.actionLabel, this.targetTab});
  final String text;
  final String? actionLabel;
  final int? targetTab;
}

_AssistantReply _assistantReply(String question) {
  final text = question.toLowerCase();
  bool has(List<String> words) => words.any(text.contains);
  if (has([
    'sign in',
    'login',
    'log in',
    'cannot log in',
    'di makalogin',
    'hindi makalogin',
  ]))
    return const _AssistantReply(
      'Use your registered email and password on the sign-in screen. If you cannot access your account, use “Forgot Password?” to request a reset email. You can also use Contact Support or Report Login Issue on the sign-in screen.',
    );
  if (has(['sign up', 'register', 'create account', 'gumawa ng account']))
    return const _AssistantReply(
      'On the sign-in screen, choose the option to create an account. Enter a valid Gmail address and your details, then verify the email link before using protected LifeLink features.',
    );
  if (has([
    'password',
    'forgot password',
    'reset password',
    'palitan ang password',
    'change password',
  ]))
    return const _AssistantReply(
      'To change your password, open Profile and choose Change Password. If you cannot sign in, select “Forgot Password?” on the sign-in screen and use the reset link sent to your email. Use at least 8 characters, including uppercase and lowercase letters, a number, and a special character.',
      actionLabel: 'Open Profile',
      targetTab: 4,
    );
  if (has([
    'verify email',
    'email verification',
    'verification link',
    'email link',
    'i verify',
    'beripika',
  ]))
    return const _AssistantReply(
      'LifeLink requires email verification for protected actions such as creating requests or sending messages. Open the verification email, tap the link, then return to the app. You can request a new verification link if needed.',
    );
  if (has(['notification', 'push notification', 'alert', 'notif']))
    return const _AssistantReply(
      'Open Profile and use the Push Notifications switch to turn LifeLink alerts on or off. The Notifications tab shows updates related to requests, donors, and support messages.',
      actionLabel: 'Open Profile',
      targetTab: 4,
    );
  if (has([
    'mark all read',
    'delete read',
    'unread notification',
    'basahin ang notification',
  ]))
    return const _AssistantReply(
      'Open the Notifications tab from the bottom navigation. You can use Mark all as read to clear unread status, or Delete read to remove read notification entries.',
    );
  if (has([
    'available to donate',
    'availability',
    'available donor',
    'availability status',
    'mag donate',
  ]))
    return const _AssistantReply(
      'Open Profile and use the Available to Donate switch to update your donor availability. Keep it accurate so requesters can find suitable donors.',
      actionLabel: 'Open Profile',
      targetTab: 4,
    );
  if (has([
    'edit request',
    'update request',
    'change request',
    'baguhin ang request',
  ]))
    return const _AssistantReply(
      'Open My Requests, select your active request, and choose Edit request. Update the details carefully so donors see the most accurate blood type, hospital, urgency, and location.',
      actionLabel: 'Open My Requests',
      targetTab: 2,
    );
  if (has(['blood bags', 'bags needed', 'number of bags', 'ilang bags']))
    return const _AssistantReply(
      'When creating or editing a request, enter the number of blood bags required by the treating hospital. LifeLink accepts a value from 1 to 100; confirm the actual amount with hospital staff.',
    );
  if (has(['cancel request', 'delete request', 'remove request', 'kanselahin']))
    return const _AssistantReply(
      'Open My Requests, select the active request, and choose Cancel request. Cancelled and completed requests move to request history, where they can be removed from history if needed.',
      actionLabel: 'Open My Requests',
      targetTab: 2,
    );
  if (has([
    'complete request',
    'mark as done',
    'request history',
    'history',
    'completed',
  ]))
    return const _AssistantReply(
      'Open My Requests and use the history icon to view completed or cancelled requests. An accepted request can be marked as done when the coordination is finished.',
      actionLabel: 'Open My Requests',
      targetTab: 2,
    );
  if (has(['location', 'map', 'pin', 'address', 'lokasyon']))
    return const _AssistantReply(
      'When creating a request, use Set Location on Map and tap the map to place a pin. Your exact pin stays private until a donor accepts the request; other users only see the city before acceptance.',
    );
  if (has(['filter', 'distance', 'city', 'search donor', 'blood filter']))
    return const _AssistantReply(
      'In Find Donors, select a blood type, enter a city, and adjust the distance controls before choosing Search Donors. Try a wider distance or another city if no matches appear.',
      actionLabel: 'Open Find Donors',
      targetTab: 1,
    );
  if (has(['accept request', 'respond request', 'help requester', 'accept']))
    return const _AssistantReply(
      'Open an active request, review its blood type, hospital, urgency, and location, then choose Accept Request. After acceptance, you can coordinate with the requester through LifeLink messages.',
    );
  if (has(['mute', 'block', 'conversation settings', 'chat settings']))
    return const _AssistantReply(
      'Open a conversation, then select the conversation settings menu. You can mute notifications for that chat or block a contact. A blocked contact can no longer receive messages from you.',
    );
  if (has(['sign out', 'logout', 'log out', 'mag logout']))
    return const _AssistantReply(
      'Open Profile and choose Log Out. You can sign in again later to access your account, donor activity, requests, and messages.',
      actionLabel: 'Open Profile',
      targetTab: 4,
    );
  if (has(['about', 'what is lifelink', 'about lifelink']))
    return const _AssistantReply(
      'LifeLink connects blood donors with people who need blood requests, helping communities find and coordinate support without relying only on social media posts.',
      actionLabel: 'Open Profile',
      targetTab: 4,
    );
  if (has(['emergency', 'critical', 'bleeding', 'unconscious', 'nahihilo']))
    return const _AssistantReply(
      'If this is a medical emergency, contact your hospital or local emergency services immediately. LifeLink can help coordinate a request, but it does not replace emergency medical care.',
      actionLabel: 'Open My Requests',
      targetTab: 2,
    );
  if (has(['find donor', 'donor', 'hanap', 'nearby', 'malapit']))
    return const _AssistantReply(
      'Open Find Donors, select the needed blood type, and enter a city to view available matches. Donor locations are protected for privacy until a request is accepted.',
      actionLabel: 'Open Find Donors',
      targetTab: 1,
    );
  if (has(['request', 'kailangan', 'need blood', 'humingi', 'create']))
    return const _AssistantReply(
      'Open My Requests and create a request. Provide the blood type, hospital, urgency, contact number, and location so donors can respond faster.',
      actionLabel: 'Open My Requests',
      targetTab: 2,
    );
  if (has(['message', 'chat', 'contact', 'kausap', 'usap']))
    return const _AssistantReply(
      'You can message a donor or requester after a match or accepted request. Open the chat icon on Home, or select a donor or request to start coordinating.',
    );
  if (has([
    'profile',
    'account',
    'edit',
    'update',
    'availability',
    'available',
  ]))
    return const _AssistantReply(
      'Open Profile to update your personal details, blood type, city, and donor availability. Accurate information helps LifeLink show better matches.',
      actionLabel: 'Open Profile',
      targetTab: 4,
    );
  if (has([
    'phone',
    'contact number',
    'barangay',
    'province',
    'personal information',
  ]))
    return const _AssistantReply(
      'Open Profile and choose Edit Information. Complete your name, 11-digit contact number, barangay, city, and province, then save the changes.',
    );
  if (has(['smart rank', 'rank', 'matching', 'match']))
    return const _AssistantReply(
      'Smart Rank prioritizes donor results using blood-type compatibility, availability, and location. You can still filter results by blood type and city.',
    );
  if (has([
    'blood type',
    'blood group',
    'abo',
    'a+',
    'a-',
    'b+',
    'b-',
    'ab+',
    'ab-',
    'o+',
    'o-',
  ]))
    return const _AssistantReply(
      'Blood type compatibility must always be confirmed by qualified hospital or blood-bank staff before transfusion. In LifeLink, use the blood type stated by the treating hospital.',
    );
  if (has([
    'donate',
    'donation',
    'eligible',
    'eligibility',
    'pwede mag donate',
  ]))
    return const _AssistantReply(
      'Donation eligibility is decided by a licensed blood collection center after screening. Contact a hospital or blood bank for its current requirements, and do not donate if you feel unwell.',
      actionLabel: 'Open Profile',
      targetTab: 4,
    );
  if (has(['safe', 'risk', 'side effect', 'masama', 'dizzy']))
    return const _AssistantReply(
      'For blood donation safety or symptoms, speak with qualified staff at a licensed blood bank or hospital. If symptoms are severe, seek urgent medical care.',
    );
  if (has(['blood', 'dugo', 'transfusion', 'hospital', 'donation']))
    return const _AssistantReply(
      'For blood donation, transfusion, or hospital questions, a licensed blood bank or treating hospital can give the safest answer for the specific patient. LifeLink can help you find donors or create a blood request, but it cannot provide a diagnosis or decide medical treatment.',
    );
  return const _AssistantReply(
    'I can help with LifeLink features and common blood donation or blood request questions. Ask in English or Tagalog. For personal medical advice, please contact a qualified healthcare professional.',
  );
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
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data =
        snapshot.data()?['userInformation'] as Map<String, dynamic>? ?? {};
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
    if ([
      _name,
      _phone,
      _barangay,
      _city,
      _province,
    ].any((field) => field.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all information fields.')),
      );
      return;
    }
    if (_phone.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact number must contain 11 digits.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final city = _city.text.trim();
      final address =
          '${_barangay.text.trim()}, $city, ${_province.text.trim()}';
      final userDocument = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
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
      final info =
          profile.data()?['userInformation'] as Map<String, dynamic>? ?? {};
      final coordinates = await LocationGeocodingService.findPhilippineCity(
        city: city,
        province: _province.text,
      );
      await FirebaseFirestore.instance.collection('donors').doc(user.uid).set({
        'name': name,
        'bloodType': info['bloodType'] as String? ?? '',
        'city': city,
        'address': address,
        'phone': _phone.text.trim(),
        'isAvailable': (info['bloodType'] as String? ?? '').isNotEmpty,
        if (coordinates != null) ...{
          'latitude': coordinates.latitude,
          'longitude': coordinates.longitude,
        },
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Information updated.')));
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Unable to update information.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _barangay, _city, _province]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _page(
    title: 'Edit Information',
    subtitle: 'Keep your contact details current for better donor matches.',
    icon: Icons.person_outline_rounded,
    child: _loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _red),
            ),
          )
        : _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    color: LifeLinkColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _label('Full Name'),
                _input(
                  _name,
                  'Enter your full name',
                  prefix: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: 14),
                _label('Contact Number'),
                _input(
                  _phone,
                  '09xx xxx xxxx',
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 14),
                _label('Barangay'),
                _input(
                  _barangay,
                  'Enter barangay',
                  prefix: const Icon(Icons.home_outlined),
                ),
                const SizedBox(height: 14),
                _label('City / Municipality'),
                _input(
                  _city,
                  'Enter city or municipality',
                  prefix: const Icon(Icons.location_city_outlined),
                ),
                const SizedBox(height: 14),
                _label('Province'),
                _input(
                  _province,
                  'Enter province',
                  prefix: const Icon(Icons.map_outlined),
                ),
                const SizedBox(height: 24),
                _primaryButton(
                  _saving ? 'Saving...' : 'Save Changes',
                  _saving ? () {} : _save,
                ),
              ],
            ),
          ),
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

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmedPassword.isEmpty) {
      _showMessage('Please complete all password fields.');
      return;
    }
    final passwordError = PasswordPolicy.validationMessage(newPassword);
    if (passwordError != null) {
      _showMessage(passwordError);
      return;
    }
    if (newPassword != confirmedPassword) {
      _showMessage('New passwords do not match.');
      return;
    }
    if (currentPassword == newPassword) {
      _showMessage(
        'Your new password must be different from the current password.',
      );
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
        'wrong-password' ||
        'invalid-credential' => 'Your current password is incorrect.',
        'weak-password' => 'Choose a stronger password.',
        'requires-recent-login' =>
          'Please sign in again, then try changing your password.',
        _ => error.message ?? 'Unable to update your password.',
      };
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => _page(
    title: 'Change Password',
    subtitle: 'Use a strong password to keep your LifeLink account secure.',
    icon: Icons.shield_outlined,
    child: _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: _red, size: 19),
              SizedBox(width: 8),
              Text(
                'Password details',
                style: TextStyle(
                  color: LifeLinkColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Current Password'),
          _password(
            _current,
            'Enter current password',
            _obscureCurrent,
            () => setState(() => _obscureCurrent = !_obscureCurrent),
            icon: Icons.lock_open_outlined,
          ),
          const SizedBox(height: 17),
          _label('New Password'),
          _password(
            _next,
            'Enter new password',
            _obscureNext,
            () => setState(() => _obscureNext = !_obscureNext),
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 8),
          PasswordRequirements(password: _next.text),
          const SizedBox(height: 17),
          _label('Confirm New Password'),
          _password(
            _confirm,
            'Re-enter new password',
            _obscureConfirm,
            () => setState(() => _obscureConfirm = !_obscureConfirm),
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 10),
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
    VoidCallback onToggle, {
    required IconData icon,
  }) => _input(
    controller,
    hint,
    obscureText: obscure,
    onChanged: (_) => setState(() {}),
    prefix: Icon(icon, color: LifeLinkColors.muted, size: 20),
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      color: const Color(0x77ffffff),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    size: 30,
                    color: Color(0xffe33135),
                  ),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13),
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
                      style: TextStyle(color: Color(0xff62738d), height: 1.4),
                    ),
                    SizedBox(height: 15),
                    Center(
                      child: Text(
                        '© 2026 LifeLink. All rights reserved.',
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
  final _scroll = ScrollController();
  final List<_AssistantMessage> _messages = [
    const _AssistantMessage(
      text:
          'Hello! I am the LifeLink Assistant. Ask in English or Tagalog. I reply in English and can help with LifeLink, blood donation, and blood requests.',
      isUser: false,
    ),
  ];

  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>>? get _historyDocument {
    final user = FirebaseAuth.instance.currentUser;
    return user == null
        ? null
        : FirebaseFirestore.instance.collection('assistantChats').doc(user.uid);
  }

  Future<void> _loadHistory() async {
    final document = _historyDocument;
    if (document == null) {
      if (mounted) setState(() => _loadingHistory = false);
      return;
    }
    try {
      final snapshot = await document.get();
      final saved = snapshot.data()?['messages'] as List<dynamic>?;
      final messages = saved
          ?.whereType<Map<dynamic, dynamic>>()
          .map(
            (item) =>
                _AssistantMessage.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.text.isNotEmpty)
          .toList();
      if (mounted && messages != null && messages.isNotEmpty) {
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
        });
      }
    } on FirebaseException {
      // The assistant remains usable even if history is temporarily offline.
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _saveHistory() async {
    final document = _historyDocument;
    if (document == null) return;
    try {
      await document.set({
        'messages': _messages
            .skip(_messages.length > 80 ? _messages.length - 80 : 0)
            .map((message) => message.toJson())
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      // A failed save must not interrupt an assistant response.
    }
  }

  void _send([String? question]) {
    final text = (question ?? _message.text).trim();
    if (text.isEmpty) return;
    final reply = _assistantReply(text);
    setState(() {
      _messages.add(_AssistantMessage(text: text, isUser: true));
      _messages.add(
        _AssistantMessage(
          text: reply.text,
          isUser: false,
          actionLabel: reply.actionLabel,
          targetTab: reply.targetTab,
        ),
      );
      _message.clear();
    });
    _saveHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients)
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
    });
  }

  void _openTab(int tab) {
    appTabIndex.value = tab;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pageBg,
    appBar: _appBar(context, 'LifeLink Assistant'),
    body: Column(
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children:
              [
                    'How do I find a donor?',
                    'How to create a request?',
                    'What is Smart Rank?',
                    'How do I message someone?',
                  ]
                  .map(
                    (text) => ActionChip(
                      label: Text(text),
                      labelStyle: const TextStyle(color: _red, fontSize: 13),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xffcf2929)),
                      onPressed: () => _send(text),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 4),
        if (_messages.isEmpty)
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
                        BoxShadow(color: Color(0x11000000), blurRadius: 3),
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
        Expanded(
          child: _loadingHistory
              ? const Center(child: CircularProgressIndicator(color: _red))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _AssistantBubble(
                    message: _messages[index],
                    onOpenTab: _openTab,
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    onSubmitted: _send,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about LifeLink...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xffdfe3e9)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _red,
                  child: IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
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
