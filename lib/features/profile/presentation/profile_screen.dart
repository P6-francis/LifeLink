import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../app/lifelink_theme.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../messaging/presentation/messages_screen.dart';
import 'profile_details_screens.dart';
import '../../../widgets/async_state_view.dart';
import '../../../services/push_notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _red = Color(0xffcf2929);
  static const _cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const _cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  bool _availableToDonate = true;
  bool _availabilityLoaded = false;
  bool _pushNotifications = false;
  bool _uploadingAvatar = false;
  String? _lastDonorDirectorySignature;

  Future<void> _showAvatarActions() async {
    if (_uploadingAvatar) return;
    final shouldUpload = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: LifeLinkColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile photo',
                  style: TextStyle(
                    color: Color(0xff13223c),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose an image from your gallery.',
                  style: TextStyle(color: Color(0xff687891)),
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => Navigator.pop(sheetContext, true),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: _red, width: 1.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xffcf2929),
                          child: Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload photo',
                                style: TextStyle(
                                  color: Color(0xff13223c),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select an image from your device',
                                style: TextStyle(
                                  color: Color(0xff687891),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _red),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  style: TextButton.styleFrom(
                    foregroundColor: _red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (shouldUpload == true && mounted) await _chooseAndUploadAvatar();
  }

  Future<void> _chooseAndUploadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _uploadingAvatar) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 82,
    );
    if (image == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
        throw const _AvatarUploadException(
          'Profile photo upload is not configured yet.',
        );
      }
      final bytes = await image.readAsBytes();
      const maxBytes = 5 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        throw const _AvatarUploadException(
          'Choose an image smaller than 5 MB.',
        );
      }

      final request =
          http.MultipartRequest(
              'POST',
              Uri.https(
                'api.cloudinary.com',
                '/v1_1/$_cloudinaryCloudName/image/upload',
              ),
            )
            ..fields['upload_preset'] = _cloudinaryUploadPreset
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: 'avatar-${user.uid}.jpg',
              ),
            );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final url = payload['secure_url'] as String?;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          url == null) {
        final error = payload['error'] as Map<String, dynamic>?;
        throw _AvatarUploadException(
          error?['message'] as String? ??
              'Unable to upload your profile photo.',
        );
      }

      await Future.wait([
        user.updatePhotoURL(url),
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'avatarUrl': url,
          'avatarUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        FirebaseFirestore.instance
            .collection('profileAvatars')
            .doc(user.uid)
            .set({
              'avatarUrl': url,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true)),
        FirebaseFirestore.instance.collection('donors').doc(user.uid).set({
          'avatarUrl': url,
        }, SetOptions(merge: true)),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
    } on _AvatarUploadException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Unable to upload your profile photo.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to upload your profile photo. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _loadPushNotificationPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final device = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pushDevices')
        .doc('current')
        .get();
    if (mounted) setState(() => _pushNotifications = device.exists);
  }

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
    required String? avatarUrl,
  }) {
    final name =
        (information?['fullName'] as String?)?.trim().isNotEmpty == true
        ? (information?['fullName'] as String).trim()
        : fallbackName;
    final bloodType = (information?['bloodType'] as String?)?.trim() ?? '';
    final city = _cityFromProfile(information);
    final address = (information?['address'] as String?)?.trim() ?? '';
    final phone = (information?['phone'] as String?)?.trim() ?? '';
    final isAvailable =
        _availableToDonate && bloodType.isNotEmpty && city.isNotEmpty;
    final signature =
        '${user.uid}|$name|$bloodType|$city|$address|$phone|$isAvailable|$avatarUrl';
    if (_lastDonorDirectorySignature == signature) return;
    _lastDonorDirectorySignature = signature;

    FirebaseFirestore.instance
        .collection('donors')
        .doc(user.uid)
        .set({
          'name': name,
          'bloodType': bloodType,
          'city': city,
          'address': address,
          'phone': phone,
          'isAvailable': isAvailable,
          if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
        }, SetOptions(merge: true))
        .catchError((_) {});
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
      await FirebaseFirestore.instance.collection('donors').doc(user.uid).set({
        'isAvailable': value,
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _availableToDonate = previousValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Unable to update availability.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _loadPushNotificationPreference();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: AsyncStateView.loading(label: 'Loading profile...'),
          );
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
              : FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return Scaffold(
                body: AsyncStateView.error(error: profileSnapshot.error),
              );
            }
            if (user != null && !profileSnapshot.hasData) {
              return const Scaffold(
                body: AsyncStateView.loading(
                  label: 'Loading profile details...',
                ),
              );
            }
            final userInformation =
                profileSnapshot.data?.data()?['userInformation']
                    as Map<String, dynamic>?;
            final bloodType = (userInformation?['bloodType'] as String?)
                ?.trim();
            final storedAvatarUrl =
                (profileSnapshot.data?.data()?['avatarUrl'] as String?)?.trim();
            final avatarUrl = storedAvatarUrl?.isNotEmpty == true
                ? storedAvatarUrl
                : user?.photoURL?.trim();
            if (user != null && _availabilityLoaded) {
              _syncDonorDirectory(
                user: user,
                information: userInformation,
                fallbackName: name,
                avatarUrl: avatarUrl,
              );
            }

            return Scaffold(
              backgroundColor: LifeLinkColors.canvas,
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffdf3e49), Color(0xffc92231)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Color(0xffffd6d6)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12cf2929),
                            blurRadius: 20,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROFILE',
                            style: TextStyle(
                              color: Color(0xe6ffffff),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _ProfileAvatar(
                                imageUrl: avatarUrl,
                                initial: initial,
                                uploading: _uploadingAvatar,
                                onTap: _showAvatarActions,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xe6ffffff),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 5,
                                      children: [
                                        _HeaderPill(
                                          label:
                                              'Blood Type: ${bloodType?.isNotEmpty == true ? bloodType : 'Not specified'}',
                                          color: const Color(0x33ffffff),
                                          foreground: Colors.white,
                                          icon: Icons.water_drop_outlined,
                                        ),
                                        _HeaderPill(
                                          label: _availableToDonate
                                              ? 'Available'
                                              : 'Unavailable',
                                          color: _availableToDonate
                                              ? const Color(0xffe8f5ec)
                                              : const Color(0xfffce9e9),
                                          foreground: _availableToDonate
                                              ? const Color(0xff27824b)
                                              : LifeLinkColors.red,
                                          icon: _availableToDonate
                                              ? Icons.check_rounded
                                              : Icons.remove_rounded,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Divider(
                              height: 1,
                              color: LifeLinkColors.border,
                            ),
                          ),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: user == null
                                ? null
                                : FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('requests')
                                      .snapshots(),
                            builder: (context, requestSnapshot) {
                              final requests = requestSnapshot.data?.docs;
                              final completedCount =
                                  requests
                                      ?.where(
                                        (request) =>
                                            (request.data()['status']
                                                    as String? ??
                                                '') ==
                                            'Completed',
                                      )
                                      .length ??
                                  0;
                              final activeCount =
                                  requests?.where((request) {
                                    final status =
                                        request.data()['status'] as String? ??
                                        'Active';
                                    return status == 'Active' ||
                                        status == 'Accepted';
                                  }).length ??
                                  0;
                              return _ProfileStats(
                                completedCount: completedCount,
                                activeCount: activeCount,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _sectionLabel('ACCOUNT'),
                        const SizedBox(height: 6),

                        _group([
                          _menu(
                            icon: Icons.person_outline,
                            title: 'Edit Information',
                            subtitle: 'Name, phone number and location',
                            onTap: () => _open(const EditInformationScreen()),
                          ),
                          _menu(
                            icon: Icons.lock_outline_rounded,
                            title: 'Change Password',
                            subtitle: 'Update your sign-in password',
                            onTap: () => _open(const ChangePasswordScreen()),
                          ),
                          _menu(
                            icon: Icons.forum_outlined,
                            title: 'Messages',
                            subtitle:
                                'Conversations with donors and requesters',
                            onTap: () => _open(const MessagesScreen()),
                          ),
                        ]),

                        const SizedBox(height: 13),

                        _sectionLabel('DONOR SETTINGS'),
                        const SizedBox(height: 6),

                        _group([
                          _toggleMenu(
                            icon: Icons.water_drop,
                            title: 'Available to Donate',
                            subtitle: 'Show up in nearby donor searches',
                            value: _availableToDonate,
                            onChanged: _setAvailability,
                          ),
                        ]),
                        const SizedBox(height: 13),

                        _sectionLabel('PREFERENCES'),
                        const SizedBox(height: 6),

                        _group([
                          _toggleMenu(
                            icon: Icons.notifications,
                            title: 'Push Notifications',
                            subtitle: 'Alerts for requests and messages',
                            value: _pushNotifications,
                            onChanged: (value) async {
                              final saved = await PushNotificationService
                                  .instance
                                  .setEnabled(value);
                              if (!mounted) return;
                              setState(
                                () =>
                                    _pushNotifications = saved ? value : false,
                              );
                              if (!saved && value) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Allow notifications in your phone settings to turn this on.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          _menu(
                            icon: Icons.info,
                            title: 'About LifeLink',
                            subtitle: 'Learn about our mission',
                            onTap: () => _open(const AboutLifeLinkScreen()),
                          ),
                          _menu(
                            icon: Icons.help,
                            title: 'LifeLink Assistant',
                            subtitle: 'Get help using the app',
                            onTap: () => _open(const HelpSupportScreen()),
                          ),
                        ]),

                        const SizedBox(height: 13),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final shouldLogOut = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(
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
                                        borderRadius: BorderRadius.circular(24),
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
                                            backgroundColor: Colors.white,
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
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          const Color(
                                                            0xff52627c,
                                                          ),
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xffdfe3e9,
                                                        ),
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
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
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: _red,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
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

                              if (shouldLogOut == true && context.mounted) {
                                await FirebaseAuth.instance.signOut();

                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.logout, size: 17),
                            label: const Text(
                              'Log Out',
                              style: TextStyle(fontWeight: FontWeight.w700),
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
    padding: const EdgeInsets.only(left: 5, top: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: LifeLinkColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _group(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: LifeLinkColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0917233b),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 66,
              endIndent: 14,
              color: LifeLinkColors.border,
            ),
        ],
      ],
    ),
  );

  Widget _menu({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    minVerticalPadding: 8,
    onTap: onTap,
    leading: _icon(icon),
    title: Text(
      title,
      style: const TextStyle(
        color: LifeLinkColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: subtitle == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LifeLinkColors.muted,
                fontSize: 11.5,
              ),
            ),
          ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 21,
      color: LifeLinkColors.muted,
    ),
  );

  Widget _toggleMenu({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    minVerticalPadding: 8,
    leading: _icon(icon),
    title: Text(
      title,
      style: const TextStyle(
        color: LifeLinkColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: subtitle == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: LifeLinkColors.muted,
                fontSize: 11.5,
              ),
            ),
          ),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: _red,
      inactiveThumbColor: _red,
      inactiveTrackColor: Colors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );

  Widget _icon(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: LifeLinkColors.redSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: _red, size: 20),
  );
}

class _AvatarUploadException implements Exception {
  const _AvatarUploadException(this.message);

  final String message;
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.initial,
    required this.uploading,
    required this.onTap,
  });

  final String? imageUrl;
  final String initial;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Change profile photo',
    child: InkWell(
      onTap: uploading ? null : onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: LifeLinkColors.redSoft,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: LifeLinkColors.redSoft,
              backgroundImage: imageUrl == null
                  ? null
                  : NetworkImage(imageUrl!),
              onBackgroundImageError: imageUrl == null ? null : (_, __) {},
              child: imageUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: LifeLinkColors.red,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
          const Positioned(
            right: -1,
            bottom: -1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: LifeLinkColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (uploading)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.label,
    required this.color,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: foreground),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ).copyWith(color: foreground),
        ),
      ],
    ),
  );
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.completedCount,
    required this.activeCount,
  });

  final int completedCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ProfileStatValue(
          icon: Icons.check_circle_outline_rounded,
          number: '$completedCount',
          label: 'Completed',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _ProfileStatValue(
          icon: Icons.water_drop_outlined,
          number: '$activeCount',
          label: 'Active requests',
        ),
      ),
    ],
  );
}

class _ProfileStatValue extends StatelessWidget {
  const _ProfileStatValue({
    required this.icon,
    required this.number,
    required this.label,
  });

  final IconData icon;
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffffdede)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: LifeLinkColors.redSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: LifeLinkColors.red),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: LifeLinkColors.ink,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LifeLinkColors.muted,
                  fontSize: 10,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
