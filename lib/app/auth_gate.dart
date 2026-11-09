import 'package:cloud_firestore/cloud_firestore.dart';
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
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (profileSnapshot.data?.data()?['isBanned'] == true) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.block_rounded, color: Color(0xffcf2929), size: 52),
                        const SizedBox(height: 16),
                        const Text('Account suspended', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Your LifeLink account has been suspended after an admin review.', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        OutlinedButton(onPressed: FirebaseAuth.instance.signOut, child: const Text('Sign out')),
                      ]),
                    ),
                  ),
                );
              }
              return const AppShell();
            },
          );
        }

        if (user != null) return const EmailVerificationScreen();

        return const AuthScreen();
      },
    );
  }
}
