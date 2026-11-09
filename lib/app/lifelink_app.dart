import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'connectivity_gate.dart';
import 'lifelink_theme.dart';
import '../features/auth/presentation/password_reset_screen.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

class LifeLinkApp extends StatefulWidget {
  const LifeLinkApp({super.key});

  @override
  State<LifeLinkApp> createState() => _LifeLinkAppState();
}

class _LifeLinkAppState extends State<LifeLinkApp>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _authSubscription;
  Timer? _presenceTimer;
  String? _presenceUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForPasswordResetLinks();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_presenceUserId != null && _presenceUserId != user?.uid) {
        _setPresence(_presenceUserId!, online: false);
      }
      _presenceUserId = user?.uid;
      _updatePresence();
      _presenceTimer?.cancel();
      if (FirebaseAuth.instance.currentUser != null) {
        _presenceTimer = Timer.periodic(
          const Duration(seconds: 45),
          (_) => _updatePresence(),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updatePresence(online: false);
    }
  }

  Future<void> _updatePresence({bool online = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _setPresence(user.uid, online: online);
  }

  Future<void> _setPresence(String userId, {required bool online}) async {
    try {
      await FirebaseFirestore.instance.collection('presence').doc(userId).set({
        'online': online,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Presence is an enhancement and must not block the app.
    }
  }

  Future<void> _listenForPasswordResetLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) _openResetScreen(initialLink);
    _linkSubscription = _appLinks.uriLinkStream.listen(_openResetScreen);
  }

  void _openResetScreen(Uri link) {
    // Firebase action links can wrap the action URL in a `link` parameter.
    final nestedLink = link.queryParameters['link'];
    final actionLink = nestedLink == null ? link : Uri.tryParse(nestedLink) ?? link;
    final code = actionLink.queryParameters['oobCode'] ?? link.queryParameters['oobCode'];
    final mode = actionLink.queryParameters['mode'] ?? link.queryParameters['mode'];
    if (mode != 'resetPassword' || code == null || code.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => PasswordResetScreen(actionCode: code)),
      );
    });
  }

  @override
  void dispose() {
    if (_presenceUserId != null) _setPresence(_presenceUserId!, online: false);
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    _presenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'LifeLink',
      theme: LifeLinkTheme.light,
      home: const ConnectivityGate(child: AuthGate()),
    );
  }
}
