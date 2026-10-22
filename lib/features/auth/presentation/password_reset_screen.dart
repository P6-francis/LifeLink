import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shown only after Firebase has verified the one-time reset code in the email
/// link. The code is never created or trusted by the app itself.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key, required this.actionCode});

  final String actionCode;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  static const _red = Color(0xffcf2929);
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isCheckingCode = true;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _email;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    try {
      final email = await FirebaseAuth.instance.verifyPasswordResetCode(widget.actionCode);
      if (mounted) setState(() => _email = email);
    } on FirebaseAuthException catch (_) {
      if (mounted) setState(() => _codeError = 'This reset link is invalid or has expired. Request a new one and try again.');
    } finally {
      if (mounted) setState(() => _isCheckingCode = false);
    }
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 8) return 'Use at least 8 characters.';
    return null;
  }

  Future<void> _savePassword() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.actionCode,
        newPassword: _password.text,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.code == 'weak-password' ? 'Choose a stronger password.' : 'Unable to reset password. Request a new link and try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _fieldDecoration({required String label, required bool obscure, required VoidCallback toggle}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xff53617a)),
        filled: true,
        fillColor: const Color(0xfff7f8fa),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          color: const Color(0xff53617a),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _isCheckingCode
              ? const Center(child: CircularProgressIndicator())
              : _codeError != null
                  ? _ResetLinkError(message: _codeError!)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            IconButton(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back, color: _red),
                              tooltip: 'Back',
                            ),
                            const SizedBox(height: 50),
                            const Icon(Icons.lock_reset_rounded, color: _red, size: 58),
                            const SizedBox(height: 24),
                            const Text('Create a new password', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff13223c), fontSize: 24, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Text('Create a strong password for $_email.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff53617a), fontSize: 14, height: 1.4)),
                            const SizedBox(height: 42),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              validator: _validatePassword,
                              decoration: _fieldDecoration(label: 'New password', obscure: _obscurePassword, toggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _confirmPassword,
                              obscureText: _obscureConfirmation,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _savePassword(),
                              validator: (value) => value != _password.text ? 'Passwords do not match.' : null,
                              decoration: _fieldDecoration(label: 'Confirm new password', obscure: _obscureConfirmation, toggle: () => setState(() => _obscureConfirmation = !_obscureConfirmation)),
                            ),
                            const SizedBox(height: 12),
                            const Text('Use at least 8 characters.', style: TextStyle(color: Color(0xff69758b), fontSize: 12)),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: _isSaving ? null : _savePassword,
                                style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: _isSaving
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      );
}

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(color: Color(0xffe8f6ec), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 70, color: Color(0xff20a45a)),
                ),
                const SizedBox(height: 26),
                const Text('Password reset!', style: TextStyle(color: Color(0xff13223c), fontSize: 25, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Text('Your password has been changed successfully. You can now sign in with your new password.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff53617a), fontSize: 14, height: 1.45)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xffcf2929), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Back to sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ResetLinkError extends StatelessWidget {
  const _ResetLinkError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.link_off_rounded, color: Color(0xffcf2929), size: 62),
                const SizedBox(height: 22),
                const Text('Link unavailable', style: TextStyle(color: Color(0xff13223c), fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff53617a), fontSize: 14, height: 1.45)),
                const Spacer(),
                TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Back to sign in')),
              ],
            ),
          ),
        ),
      );
}
