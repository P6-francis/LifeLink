import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';

/// Must stay top-level so Android can invoke it when the app is backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Registers this phone for FCM and calls the separate Cloudflare Worker.
/// Its URL is supplied at build time, never with credentials in the app.
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();
  static const _deviceDocument = 'current';
  static const _workerUrl = String.fromEnvironment(
    'LIFELINK_NOTIFICATION_WORKER_URL',
  );

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _saveTokenIfEnabled(user);
    });
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) _saveTokenIfEnabled(user);
    });
  }

  Future<bool> setEnabled(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final device = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pushDevices')
        .doc(_deviceDocument);

    if (!enabled) {
      await device.delete();
      return true;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    await _saveToken(user);
    return true;
  }

  Future<void> _saveTokenIfEnabled(User user) async {
    try {
      final device = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pushDevices')
          .doc(_deviceDocument);
      final snapshot = await device.get();
      if (snapshot.exists) await _saveToken(user);
    } on FirebaseException {
      // Rules might still be deploying; push setup must not interrupt sign-in.
    }
  }

  Future<void> _saveToken(User user) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pushDevices')
        .doc(_deviceDocument)
        .set({
      'token': token,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sends only a chat notification. The Worker verifies that both people
  /// belong to [chatId] before it sends anything, so a client cannot notify a
  /// random account.
  Future<void> sendChatNotification({
    required String chatId,
    required String recipientId,
    required String message,
  }) async {
    if (_workerUrl.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return;

    try {
      await http.post(
        Uri.parse(_workerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'chatId': chatId,
          'recipientId': recipientId,
          'message': message,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // A sent chat must never fail just because a notification is delayed.
    }
  }

  /// Notifies the requester after a donor accepts their blood request. The
  /// Worker verifies the accepted donor and request owner before saving it.
  Future<void> sendRequestResponseNotification({
    required String requestId,
    required String recipientId,
  }) async {
    if (_workerUrl.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return;
    try {
      await http.post(
        Uri.parse(_workerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'requestId': requestId, 'recipientId': recipientId}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // The accepted request must not fail if delivery is delayed.
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _tokenSubscription?.cancel();
  }
}
