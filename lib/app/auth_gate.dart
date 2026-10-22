import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_screen.dart';
import 'app_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // This emits after User.reload(), so the gate updates as soon as the
      // user confirms the link in their email.
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null && user.emailVerified) {
          return const AppShell();
        }

        if (user != null) return const EmailVerificationScreen();

        return const AuthScreen();
      },
    );
  }
}
