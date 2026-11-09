import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shows the uploaded profile image whenever one is available. Initials remain
/// only for accounts created before profile-photo support was added.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.userId,
    this.radius = 22,
    this.backgroundColor = Colors.white,
    this.initialColor = const Color(0xffcf2929),
  });

  final String name;
  final String? imageUrl;
  final String? userId;
  final double radius;
  final Color backgroundColor;
  final Color initialColor;

  String? _nonEmpty(String? value) =>
      value?.trim().isNotEmpty == true ? value!.trim() : null;

  Widget _initialAvatar() => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
          style: TextStyle(
            color: initialColor,
            fontSize: radius * .78,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _avatar(String? url) {
    final value = _nonEmpty(url);
    if (value == null) return _initialAvatar();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: Image.network(
          value,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return _initialAvatar();
          },
          errorBuilder: (context, error, stackTrace) => _initialAvatar(),
        ),
      ),
    );
  }

  Widget _directoryAvatar(String id, String? fallbackUrl) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('donors').doc(id).snapshots(),
        builder: (context, snapshot) {
          final donorUrl =
              _nonEmpty(snapshot.data?.data()?['avatarUrl'] as String?);
          return _avatar(donorUrl ?? fallbackUrl);
        },
      );

  @override
  Widget build(BuildContext context) {
    final id = userId?.trim();
    if (id == null || id.isEmpty) return _avatar(imageUrl);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('profileAvatars')
          .doc(id)
          .snapshots(),
      builder: (context, snapshot) {
        final storedUrl = _nonEmpty(snapshot.data?.data()?['avatarUrl'] as String?);
        final currentUserUrl = id == FirebaseAuth.instance.currentUser?.uid
            ? _nonEmpty(FirebaseAuth.instance.currentUser?.photoURL)
            : null;
        final fallbackUrl = currentUserUrl ?? imageUrl;
        if (storedUrl != null) return _avatar(storedUrl);
        return _directoryAvatar(id, fallbackUrl);
      },
    );
  }
}
