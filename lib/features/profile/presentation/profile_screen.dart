import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/presentation/auth_screen.dart';
import '../../messaging/presentation/messages_screen.dart';
import 'profile_details_screens.dart';
import '../../../widgets/async_state_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _red = Color(0xffcf2929);
  bool _availableToDonate = true;
  bool _availabilityLoaded = false;
  bool _pushNotifications = true;
  String? _lastDonorDirectorySignature;

  String _cityFromProfile(Map<String, dynamic>? information) {
    final savedCity = (information?['city'] as String?)?.trim() ?? '';
    if (savedCity.isNotEmpty) return savedCity;

    final address = (information?['address'] as String?)?.trim() ?? '';
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return parts.isEmpty ? '' : parts.first;
  }

  void _syncDonorDirectory({
    required User user,
    required Map<String, dynamic>? information,
    required String fallbackName,
  }) {
    final name = (information?['fullName'] as String?)?.trim().isNotEmpty == true
        ? (information?['fullName'] as String).trim()
        : fallbackName;
    final bloodType = (information?['bloodType'] as String?)?.trim() ?? '';
    final city = _cityFromProfile(information);
    final isAvailable = _availableToDonate && bloodType.isNotEmpty && city.isNotEmpty;
    final signature = '${user.uid}|$name|$bloodType|$city|$isAvailable';
    if (_lastDonorDirectorySignature == signature) return;
    _lastDonorDirectorySignature = signature;

    FirebaseFirestore.instance.collection('donors').doc(user.uid).set({
      'name': name,
      'bloodType': bloodType,
      'city': city,
      'isAvailable': isAvailable,
    }, SetOptions(merge: true)).catchError((_) {});
  }

  Future<void> _loadAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final document = await FirebaseFirestore.instance
        .collection('donors')
        .doc(user.uid)
        .get();
    final value = document.data()?['isAvailable'];
    if (mounted) {
      setState(() {
        _availableToDonate = value is bool ? value : true;
        _availabilityLoaded = true;
      });
    }
  }

  Future<void> _setAvailability(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final previousValue = _availableToDonate;
    setState(() => _availableToDonate = value);
    try {
      await FirebaseFirestore.instance.collection('donors').doc(user.uid).set(
        {'isAvailable': value},
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _availableToDonate = previousValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to update availability.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AsyncStateView.loading(label: 'Loading profile...'));
        }
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        final storedName =
            (user?.displayName != null && user!.displayName!.isNotEmpty)
                ? user.displayName!
                : 'User';
        final name = storedName
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
        final email = user?.email ?? 'No email provided';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: user == null
              ? null
              : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return Scaffold(body: AsyncStateView.error(error: profileSnapshot.error));
            }
            if (user != null && !profileSnapshot.hasData) {
              return const Scaffold(body: AsyncStateView.loading(label: 'Loading profile details...'));
            }
            final userInformation =
                profileSnapshot.data?.data()?['userInformation']
                    as Map<String, dynamic>?;
            final bloodType = (userInformation?['bloodType'] as String?)?.trim();
            if (user != null && _availabilityLoaded) {
              _syncDonorDirectory(
                user: user,
                information: userInformation,
                fallbackName: name,
              );
            }

            return Scaffold(
          backgroundColor: const Color(0xfff7f8fa),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 17, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xffdc3035), Color(0xffc9232a)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROFILE',
                      style: TextStyle(
                        color: Color(0xffffcaca),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 29,
                          backgroundColor: const Color(0x40ffffff),
                          child: CircleAvatar(
                            radius: 27,
                            backgroundColor: const Color(0x55ffffff),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Color(0xffffd8d8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _HeaderPill(
                                    label: 'Blood Type: ${bloodType?.isNotEmpty == true ? bloodType : 'Not specified'}',
                                    color: const Color(0x33ffffff),
                                  ),
                                  const SizedBox(width: 6),
                                  _HeaderPill(
                                    label: _availableToDonate
                                        ? 'Available'
                                        : 'Unavailable',
                                    color: _availableToDonate
                                        ? const Color(0xff59aa5b)
                                        : const Color(0xff9b3036),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: user == null
                          ? null
                          : FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('requests')
                              .snapshots(),
                      builder: (context, requestSnapshot) {
                        final requestCount = requestSnapshot.data?.docs
                                .where((request) {
                                  final status =
                                      (request.data()['status'] as String? ??
                                              'Active')
                                          .toLowerCase();
                                  return status == 'active' ||
                                      status == 'completed';
                                })
                                .length ??
                            0;
                        return Row(
                          children: [
                            const Expanded(
                              child: _Stat(
                                number: '12',
                                label: 'Donations',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Stat(
                                number: '$requestCount',
                                label: 'Requests',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 13, 12, 24),
                  children: [
                    _sectionLabel('ACCOUNT'),
                    const SizedBox(height: 6),

                    _group([
                      _menu(
                        icon: Icons.person_outline,
                        title: 'Edit Information',
                        onTap: () => _open(const EditInformationScreen()),
                      ),
                      _menu(
                        icon: Icons.lock,
                        title: 'Change Password',
                        onTap: () =>
                            _open(const ChangePasswordScreen()),
                      ),
                      _menu(
                        icon: Icons.phone,
                        title: 'Contact Number',
                        onTap: () =>
                            _open(const ContactNumberScreen()),
                      ),
                      _menu(
                        icon: Icons.forum_outlined,
                        title: 'Messages',
                        onTap: () =>
                            _open(const MessagesScreen()),
                      ),
                    ]),

                    const SizedBox(height: 13),

                    _sectionLabel('DONOR SETTINGS'),
                    const SizedBox(height: 6),

                    _group([
                      _toggleMenu(
                        icon: Icons.water_drop,
                        title: 'Available to Donate',
                        value: _availableToDonate,
                        onChanged: _setAvailability,
                      ),
                      _menu(
                        icon: Icons.location_on,
                        title: 'Donation History',
                        onTap: () =>
                            _open(const DonationHistoryScreen()),
                      ),
                    ]),

                    const SizedBox(height: 13),

                    _sectionLabel('PREFERENCES'),
                    const SizedBox(height: 6),

                    _group([
                      _toggleMenu(
                        icon: Icons.notifications,
                        title: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                      _menu(
                        icon: Icons.info,
                        title: 'About LifeLink',
                        onTap: () =>
                            _open(const AboutLifeLinkScreen()),
                      ),
                      _menu(
                        icon: Icons.help,
                        title: 'Help & Support',
                        onTap: () =>
                            _open(const HelpSupportScreen()),
                      ),
                    ]),

                    const SizedBox(height: 13),

                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final shouldLogOut =
                              await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    25,
                                    24,
                                    22,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(24),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 22,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircleAvatar(
                                        radius: 28,
                                        backgroundColor:
                                            Color(0xffffe8ec),
                                        child: Icon(
                                          Icons.logout_rounded,
                                          color: _red,
                                          size: 27,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Log out of LifeLink?',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xff13223c),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'You can sign in again anytime to access your account and donor activity.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xff6e7e96),
                                          fontSize: 14,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 23),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 44,
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop(false),
                                                style:
                                                    OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(
                                                    0xff52627c,
                                                  ),
                                                  side:
                                                      const BorderSide(
                                                    color: Color(
                                                      0xffdfe3e9,
                                                    ),
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      12,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          Expanded(
                                            child: SizedBox(
                                              height: 44,
                                              child: FilledButton(
                                                onPressed: () =>
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop(true),
                                                style:
                                                    FilledButton.styleFrom(
                                                  backgroundColor:
                                                      _red,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      12,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Log Out',
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          if (shouldLogOut == true &&
                              context.mounted) {
                            await FirebaseAuth.instance.signOut();

                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AuthScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              const Color(0xffffe8ec),
                          foregroundColor: _red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(
                          Icons.logout,
                          size: 17,
                        ),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Center(
                      child: Text(
                        'LifeLink v1.0.0 · Built with ♥ for the community',
                        style: TextStyle(
                          color: Color(0xffc2cad6),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xff8b9ab2),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
      );

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  Widget _group(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: children,
        ),
      );

  Widget _menu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) =>
      ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        onTap: onTap,
        leading: _icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xff13223c),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 18,
          color: Color(0xff9aa6b5),
        ),
      );

  Widget _toggleMenu({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        leading: _icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xff13223c),
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: _red,
          inactiveThumbColor: _red,
          inactiveTrackColor: const Color(0xffffd8dc),
          materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
        ),
      );

  Widget _icon(IconData icon) => CircleAvatar(
        radius: 14,
        backgroundColor: const Color(0xffffe8ec),
        child: Icon(
          icon,
          color: _red,
          size: 16,
        ),
      );
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0x33ffffff),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xffffd6d6),
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
}
