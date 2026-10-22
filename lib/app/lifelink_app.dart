import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'connectivity_gate.dart';
import '../features/auth/presentation/password_reset_screen.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

class LifeLinkApp extends StatefulWidget {
  const LifeLinkApp({super.key});

  @override
  State<LifeLinkApp> createState() => _LifeLinkAppState();
}

class _LifeLinkAppState extends State<LifeLinkApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForPasswordResetLinks();
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
    _linkSubscription?.cancel();
    super.dispose();
  }

  static const red = Color(0xffd9283b);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'LifeLink',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: red),
        scaffoldBackgroundColor: const Color(0xfff8f8fa),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xff24242a),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffe1e1e5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffe1e1e5)),
          ),
        ),
      ),
      home: const ConnectivityGate(child: AuthGate()),
    );
  }
}
