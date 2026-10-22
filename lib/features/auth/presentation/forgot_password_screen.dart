import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand colors shared across the forgot-password flow so every step looks
/// consistent with the rest of the app.
const _red = Color(0xffcf2929);
const _ink = Color(0xff13223c);
const _muted = Color(0xff53617a);

/// The single source of truth for password-reset email settings.
///
/// Every send (initial request *and* resend) must use this so the link always
/// opens back inside the app instead of a browser. Reusing one definition
/// prevents the "resend opens in the browser" bug where the settings were
/// accidentally omitted on resend.
ActionCodeSettings _resetActionCodeSettings() => ActionCodeSettings(
      // Must be an authorized domain in Firebase Authentication.
      url: 'https://lifelink-66e5b.firebaseapp.com/reset-password',
      handleCodeInApp: true,
      androidPackageName: 'com.example.lifelink',
      androidInstallApp: true,
      iOSBundleId: 'com.example.lifelink',
    );


/// Step 1 — ask for the account email and send a password-reset link.
///
/// On success it pushes [PasswordResetSentScreen]. The link in the email opens
/// back in the app (handled by the deep-link listener) which lands on
/// `PasswordResetScreen` to actually change the password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || _isSending) return;

    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email.text.trim(),
        actionCodeSettings: _resetActionCodeSettings(),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PasswordResetSentScreen(email: _email.text.trim()),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resetErrorMessage(error))),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to send the reset email.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send the reset email. Check your connection and try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _resetErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return 'Unable to send the reset email. Please try again.';
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _ResetTopBar(onBack: () => Navigator.of(context).pop()),
              const Divider(height: 1, color: Color(0xffeeeeee)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: Color(0xffffe7eb),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset_rounded, size: 36, color: _red),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Forgot your password?',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Enter the email address linked to your account.\nWe'll send you a link to reset your password.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
                        ),
                        const SizedBox(height: 36),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email Address',
                            style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_isSending,
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _sendResetLink(),
                          style: const TextStyle(color: _ink),
                          decoration: _inputDecoration(hint: 'Enter your email'),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 53,
                          child: FilledButton(
                            onPressed: _isSending ? null : _sendResetLink,
                            style: FilledButton.styleFrom(
                              backgroundColor: _red,
                              disabledBackgroundColor: const Color(0xffe49397),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}


/// Step 2 — confirm the reset link was sent and let the user resend it.
///
/// Tapping the link in the email opens the app back up on `PasswordResetScreen`
/// (see the deep-link handler in `lifelink_app.dart`).
class PasswordResetSentScreen extends StatefulWidget {
  const PasswordResetSentScreen({super.key, required this.email});

  final String email;

  @override
  State<PasswordResetSentScreen> createState() => _PasswordResetSentScreenState();
}

class _PasswordResetSentScreenState extends State<PasswordResetSentScreen> {
  bool _isResending = false;

  // A short cooldown keeps the user from spamming resend and tripping
  // Firebase's "too-many-requests" limit.
  static const _cooldownSeconds = 30;
  int _secondsRemaining = 0;
  Timer? _cooldownTimer;

  bool get _canResend => !_isResending && _secondsRemaining == 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() => _isResending = true);
    try {
      // Reuse the shared settings so the resent link also opens in the app.
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: widget.email,
        actionCodeSettings: _resetActionCodeSettings(),
      );
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new reset link has been sent.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to resend the email. Please try again.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resend the email. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }


  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _ResetTopBar(
                title: 'Check your email',
                onBack: () => Navigator.of(context).pop(),
                tooltip: 'Change email',
              ),
              const Divider(height: 1, color: Color(0xffeeeeee)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(color: Color(0xffe8f6ec), shape: BoxShape.circle),
                        child: const Icon(Icons.mark_email_read_rounded, size: 42, color: Color(0xff238442)),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Check your inbox',
                        style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'We sent a secure reset link to',
                        style: TextStyle(color: _muted, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Tap the link in the email. It will return you to LifeLink so you can create a new password. Check your spam folder too.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _canResend ? _resend : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _red,
                            side: const BorderSide(color: _red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isResending
                              ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2.5))
                              : Text(
                                  _secondsRemaining > 0
                                      ? 'Resend email in ${_secondsRemaining}s'
                                      : 'Resend email',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Use a different email',
                          style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}


/// Shared branded header used by both forgot-password steps.
class _ResetTopBar extends StatelessWidget {
  const _ResetTopBar({required this.onBack, this.title, this.tooltip = 'Back'});

  final VoidCallback onBack;
  final String? title;
  final String tooltip;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 88,
        child: Row(
          children: [
            const SizedBox(width: 15),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 20, color: _red),
                tooltip: tooltip,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              title ?? 'Forgot Password',
              style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

/// Consistent text-field decoration for the forgot-password flow.
InputDecoration _inputDecoration({required String hint}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff777984), fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xffdedfe4)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _red, width: 1.4),
      ),
    );

