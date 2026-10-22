import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _red = Color(0xffcf2929);
  bool _signUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email.addListener(_clearLoginErrors);
    _password.addListener(_clearLoginErrors);
  }

  void _clearLoginErrors() {
    if (_emailError != null || _passwordError != null) {
      setState(() {
        _emailError = null;
        _passwordError = null;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _emailError = email.isEmpty ? 'Enter your email address.' : null;
        _passwordError = password.isEmpty ? 'Enter your password.' : null;
      });
      return;
    }

    if (_signUp && _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your full name.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_signUp) {
        // 1. Create User in Firebase Auth
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final user = userCredential.user;
        if (user != null) {
          // Update Firebase Display Name
          await user.updateDisplayName(_name.text.trim());
          await user.sendEmailVerification();

          // 2. Store profile data as one nested field in users/{uid}.
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'userInformation': {
              'uid': user.uid,
              'fullName': _name.text.trim(),
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            },
          });
          await FirebaseFirestore.instance.collection('donors').doc(user.uid).set({
            'name': _name.text.trim(),
            'bloodType': '',
            'city': '',
            'isAvailable': false,
          });
        }
      } else {
        // Log In Existing User
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (_signUp) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We sent a verification link to your email.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (!_signUp) {
        setState(() {
          _emailError = null;
          _passwordError = null;

          switch (e.code) {
            case 'invalid-email':
              _emailError = 'Enter a valid email address.';
              break;
            case 'user-not-found':
              _emailError = 'No account was found with this email.';
              break;
            case 'user-disabled':
              _emailError = 'This account has been disabled.';
              break;
            case 'wrong-password':
              _passwordError = 'Incorrect password. Please try again.';
              break;
            case 'invalid-credential':
              _passwordError = 'Incorrect email or password.';
              break;
            case 'too-many-requests':
              _passwordError = 'Too many attempts. Please try again later.';
              break;
            default:
              _passwordError = e.message ?? 'Unable to log in. Please try again.';
              break;
          }
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _field({required String hint, Widget? suffix, String? errorText}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff777984), fontSize: 14),
        suffixIcon: suffix,
        errorText: errorText,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffe9ed),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 84),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 342),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 31),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 3, offset: Offset(0, 2))],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
                        child: const Icon(Icons.water_drop_rounded, color: _red, size: 31),
                      ),
                      const SizedBox(height: 17),
                      Text(_signUp ? 'Sign Up' : 'Log In', style: const TextStyle(color: _red, fontSize: 30, fontWeight: FontWeight.w800, height: 1)),
                      const SizedBox(height: 9),
                      Text(
                        _signUp ? 'Create an account to help your community.' : 'Sign in to continue helping your\ncommunity.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xff53617a), fontSize: 14, height: 1.35),
                      ),
                      const SizedBox(height: 25),
                      if (_signUp) ...[
                        TextField(controller: _name, decoration: _field(hint: 'Full name')),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _field(
                          hint: 'Email',
                          errorText: _signUp ? null : _emailError,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: _field(
                          hint: 'Password',
                          errorText: _signUp ? null : _passwordError,
                          suffix: IconButton(
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: _red, size: 20),
                          ),
                        ),
                      ),
                      if (!_signUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            ),
                            style: TextButton.styleFrom(foregroundColor: _red, padding: const EdgeInsets.only(top: 9, bottom: 8)),
                            child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 53,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _continue,
                          style: FilledButton.styleFrom(
                            backgroundColor: _red,
                            disabledBackgroundColor: const Color(0xffe49397),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(_signUp ? 'Sign up' : 'Log in', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 9),
                      TextButton(
                        onPressed: () {
                          if (_signUp) {
                            setState(() => _signUp = false);
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const _CreateAccountPage()),
                          );
                        },
                        style: TextButton.styleFrom(foregroundColor: _red, padding: const EdgeInsets.symmetric(vertical: 4)),
                        child: Text(_signUp ? 'Already have an account? Log in' : "Don't have an account? Sign up", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      if (!_signUp) ...[
                        const Padding(padding: EdgeInsets.only(top: 14), child: Divider(color: Color(0xffeeeeee), height: 1)),
                        const SizedBox(height: 20),
                        const Text('Trouble logging in?', style: TextStyle(color: Color(0xff9aa6c0), fontSize: 13)),
                        const SizedBox(height: 12),
                        _SupportButton(
                          icon: Icons.chat_bubble,
                          label: 'Contact Support',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const _ContactSupportPage()),
                          ),
                        ),
                        const SizedBox(height: 9),
                        _SupportButton(
                          icon: Icons.mail_outline,
                          label: 'Report Login Issue',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const _ReportLoginIssuePage()),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateAccountPage extends StatefulWidget {
  const _CreateAccountPage();

  @override
  State<_CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<_CreateAccountPage> {
  static const _red = Color(0xffcf2929);

  // Text Controllers
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _barangay = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  // Dropdowns & Selectors
  String? _bloodType;
  String? _gender;
  String? _maritalStatus;
  DateTime? _birthdate;

  bool _bloodMenuOpen = false;
  bool _agreed = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _passwordsDoNotMatch =>
      _confirmPassword.text.isNotEmpty &&
      _password.text != _confirmPassword.text;

  bool get _hasValidPhoneNumber => _phone.text.length == 11;

  bool get _hasValidGmailAddress => RegExp(
        r'^[^@\s]+@gmail\.com$',
        caseSensitive: false,
      ).hasMatch(_email.text.trim());

  String _capitalizeNamePart(String value) {
    final name = value.trim();
    if (name.isEmpty) return name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  int? get _calculatedAge {
    if (_birthdate == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthdate!.year;
    if (now.month < _birthdate!.month ||
        (now.month == _birthdate!.month && now.day < _birthdate!.day)) {
      age--;
    }
    return age;
  }

  String get _formattedAddress =>
      '${_barangay.text.trim()}, ${_city.text.trim()}, ${_province.text.trim()}';

  bool get _canCreate =>
      _agreed &&
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _hasValidGmailAddress &&
      _hasValidPhoneNumber &&
      _barangay.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _province.text.trim().isNotEmpty &&
      _bloodType != null &&
      _gender != null &&
      _maritalStatus != null &&
      _birthdate != null &&
      _password.text.isNotEmpty &&
      _password.text == _confirmPassword.text;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _email,
      _phone,
      _barangay,
      _city,
      _province,
      _password,
      _confirmPassword,
    ]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _email,
      _phone,
      _barangay,
      _city,
      _province,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_hasValidGmailAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid Gmail address (example@gmail.com).'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _email.text.trim();
      final password = _password.text;

      final firstName = _capitalizeNamePart(_firstName.text);
      final mName = _capitalizeNamePart(_middleName.text);
      final lastName = _capitalizeNamePart(_lastName.text);
      final fullName = mName.isEmpty
          ? '$firstName $lastName'
          : '$firstName $mName $lastName';

      // 1. Create User in Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(fullName);
        await user.sendEmailVerification();

        // 2. Store profile data as one nested field in users/{uid}.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'userInformation': {
            'uid': user.uid,
            'firstName': firstName,
            'middleName': mName,
            'lastName': lastName,
            'fullName': fullName,
            'email': email,
            'phone': _phone.text.trim(),
            'address': _formattedAddress,
            'barangay': _barangay.text.trim(),
            'city': _city.text.trim(),
            'province': _province.text.trim(),
            'gender': _gender,
            'maritalStatus': _maritalStatus,
            'bloodType': _bloodType,
            'birthdate': Timestamp.fromDate(_birthdate!),
            'age': _calculatedAge,
            'createdAt': FieldValue.serverTimestamp(),
          },
        });
        await FirebaseFirestore.instance.collection('donors').doc(user.uid).set({
          'name': fullName,
          'bloodType': _bloodType,
          'city': _city.text.trim(),
          'isAvailable': true,
        });
      }

      // Keep the session active. AuthGate will show the verification screen
      // and deny access to the main app until the link is confirmed.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We sent a verification link to your email.')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to create account.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _field(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff777984), fontSize: 14),
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xff13223c),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 92,
                child: Row(
                  children: [
                    const SizedBox(width: 30),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xffffe7eb),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, size: 20, color: _red),
                        tooltip: 'Back',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Color(0xff13223c),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xffeeeeee)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(38, 22, 38, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('First Name'),
                      TextField(controller: _firstName, decoration: _field('First Name')),
                      const SizedBox(height: 17),

                      _label('Middle Name'),
                      TextField(controller: _middleName, decoration: _field('Middle Name (Optional)')),
                      const SizedBox(height: 17),

                      _label('Last Name'),
                      TextField(controller: _lastName, decoration: _field('Last Name')),
                      const SizedBox(height: 17),

                      _label('Email Address'),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _field('example@gmail.com'),
                      ),
                      if (_email.text.isNotEmpty && !_hasValidGmailAddress)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Enter a valid Gmail address (example@gmail.com).',
                            style: TextStyle(
                              color: Color(0xffcf2929),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 17),

                      _label('Phone Number'),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: _field('09xx xxx xxxx'),
                      ),
                      if (_phone.text.isNotEmpty && !_hasValidPhoneNumber)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Phone number must be exactly 11 digits.',
                            style: TextStyle(
                              color: Color(0xffcf2929),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 17),

                      _label('Barangay'),
                      TextField(
                        controller: _barangay,
                        textCapitalization: TextCapitalization.words,
                        decoration: _field('e.g. Barangay San Vicente'),
                      ),
                      const SizedBox(height: 17),

                      _label('City / Municipality'),
                      TextField(
                        controller: _city,
                        textCapitalization: TextCapitalization.words,
                        decoration: _field('e.g. Urdaneta City'),
                      ),
                      const SizedBox(height: 17),

                      _label('Province'),
                      TextField(
                        controller: _province,
                        textCapitalization: TextCapitalization.words,
                        decoration: _field('e.g. Pangasinan'),
                      ),
                      const SizedBox(height: 17),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Gender'),
                                DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: _field('Gender'),
                                  items: ['Male', 'Female', 'Other']
                                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _gender = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Marital Status'),
                                DropdownButtonFormField<String>(
                                  value: _maritalStatus,
                                  decoration: _field('Status'),
                                  items: ['Single', 'Married', 'Widowed', 'Separated']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _maritalStatus = val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),

                      _label('Birthdate'),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _birthdate ?? DateTime(2000),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                            helpText: 'SELECT BIRTHDATE',
                            confirmText: 'Save date',
                            cancelText: 'Cancel',
                            builder: (context, child) {
                              final baseTheme = Theme.of(context);
                              const brandRed = Color(0xffcf2929);
                              const ink = Color(0xff172033);

                              return Theme(
                                data: baseTheme.copyWith(
                                  colorScheme: baseTheme.colorScheme.copyWith(
                                    primary: brandRed,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: ink,
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    backgroundColor: Colors.white,
                                    surfaceTintColor: Colors.transparent,
                                    elevation: 8,
                                    shadowColor: const Color(0x220f172a),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    headerBackgroundColor: brandRed,
                                    headerForegroundColor: Colors.white,
                                    headerHeadlineStyle: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                    headerHelpStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                    weekdayStyle: const TextStyle(
                                      color: Color(0xff727887),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    dayStyle: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    todayBorder: const BorderSide(
                                      color: brandRed,
                                      width: 1.5,
                                    ),
                                    dayBackgroundColor:
                                        MaterialStateProperty.resolveWith((states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return brandRed;
                                      }
                                      return null;
                                    }),
                                    dayForegroundColor:
                                        MaterialStateProperty.resolveWith((states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return Colors.white;
                                      }
                                      if (states.contains(MaterialState.disabled)) {
                                        return const Color(0xffc6c9d0);
                                      }
                                      return ink;
                                    }),
                                    yearBackgroundColor:
                                        MaterialStateProperty.resolveWith((states) {
                                      return states.contains(MaterialState.selected)
                                          ? brandRed
                                          : null;
                                    }),
                                    yearForegroundColor:
                                        MaterialStateProperty.resolveWith((states) {
                                      return states.contains(MaterialState.selected)
                                          ? Colors.white
                                          : ink;
                                    }),
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: true,
                                      fillColor: const Color(0xfffff7f7),
                                      labelStyle: const TextStyle(color: brandRed),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xffd7dbe3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: brandRed, width: 2),
                                      ),
                                    ),
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: brandRed,
                                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _birthdate = picked);
                          }
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xffdedfe4)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _birthdate == null
                                      ? 'Select Birthdate'
                                      : '${_birthdate!.month}/${_birthdate!.day}/${_birthdate!.year}  (Age: ${_calculatedAge ?? 0})',
                                  style: TextStyle(
                                    color: _birthdate == null
                                        ? const Color(0xff777984)
                                        : const Color(0xff13223c),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: Color(0xff777984),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),

                      _label('Blood Type'),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => setState(() => _bloodMenuOpen = !_bloodMenuOpen),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xffdedfe4)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _bloodType ?? 'Select blood type',
                                    style: TextStyle(
                                      color: _bloodType == null
                                          ? const Color(0xff777984)
                                          : const Color(0xff13223c),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.black,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_bloodMenuOpen)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xffdedfe4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                color: const Color(0xff777777),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                child: const Text(
                                  'Select blood type',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map(
                                (type) => InkWell(
                                  onTap: () => setState(() {
                                    _bloodType = type;
                                    _bloodMenuOpen = false;
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 17),

                      _label('Password'),
                      TextField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: _field('Create a password'),
                      ),
                      const SizedBox(height: 17),

                      _label('Confirm Password'),
                      TextField(
                        controller: _confirmPassword,
                        obscureText: _obscurePassword,
                        decoration: _field('Re-enter password'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _passwordsDoNotMatch
                                  ? const Text(
                                      'Passwords do not match.',
                                      style: TextStyle(
                                        color: Color(0xffcf2929),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show passwords'
                                  : 'Hide passwords',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: _red,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),

                      Row(
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (value) => setState(() => _agreed = value ?? false),
                            activeColor: _red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Color(0xff53617a), fontSize: 12.5),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(color: _red, fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(color: _red, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),

                      SizedBox(
                        height: 49,
                        child: FilledButton(
                          onPressed: (_canCreate && !_isLoading) ? _handleCreateAccount : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _red,
                            disabledBackgroundColor: const Color(0xffe49397),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Color(0xff53617a), fontSize: 14),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(color: _red, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
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

class _ContactSupportPage extends StatefulWidget {
  const _ContactSupportPage();

  @override
  State<_ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<_ContactSupportPage> {
  static const _red = Color(0xffcf2929);
  final _message = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text: "Hi! Welcome to LifeLink Support 🩸.\nHow can we help you today?\nDescribe your issue and we'll assist\nyou right away.",
      isUser: false,
    ),
  ];
  final _scroll = ScrollController();

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(const _ChatMessage(text: 'Thanks for sharing that. Our support team will help you with this shortly.', isUser: false));
      _message.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff6f6f6),
        body: SafeArea(
          child: Column(children: [
            SizedBox(
              height: 92,
              child: Row(children: [
                const SizedBox(width: 39),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
                  child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, size: 20, color: _red), tooltip: 'Back'),
                ),
                const SizedBox(width: 12),
                const Text('Contact Support', style: TextStyle(color: Color(0xff13223c), fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
            Container(
              height: 61,
              color: const Color(0xffffe6ea),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                const CircleAvatar(radius: 18, backgroundColor: _red),
                const SizedBox(width: 13),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Text('LifeLink Support', style: TextStyle(color: Color(0xff13223c), fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('• Online · Typically replies instantly', style: TextStyle(color: Color(0xff079b38), fontSize: 12)),
                ]),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _ChatBubble(message: _messages[index]),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Describe your issue...',
                      hintStyle: TextStyle(color: Color(0xff7d8492), fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22)), borderSide: BorderSide(color: Color(0xffdedfe4))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22)), borderSide: BorderSide(color: _red, width: 1.4)),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Material(
                  color: _red,
                  shape: const CircleBorder(),
                  child: IconButton(onPressed: _send, icon: const Icon(Icons.send, color: Colors.white, size: 21), tooltip: 'Send'),
                ),
              ]),
            ),
          ]),
        ),
      );
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!message.isUser) const CircleAvatar(radius: 14, backgroundColor: Color(0xffcf2929)),
            if (!message.isUser) const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: message.isUser ? const Color(0xffcf2929) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: message.isUser ? null : const [BoxShadow(color: Color(0x0d000000), blurRadius: 3, offset: Offset(0, 2))],
                ),
                child: Text(message.text, style: TextStyle(color: message.isUser ? Colors.white : const Color(0xff13223c), fontSize: 14, height: 1.35)),
              ),
            ),
          ],
        ),
      );
}

class _ReportLoginIssuePage extends StatefulWidget {
  const _ReportLoginIssuePage();

  @override
  State<_ReportLoginIssuePage> createState() => _ReportLoginIssuePageState();
}

class _ReportLoginIssuePageState extends State<_ReportLoginIssuePage> {
  static const _red = Color(0xffcf2929);
  static const _issues = [
    "Can't log in to my account",
    'Forgot my email or password',
    'Account has been locked',
    'Verification code not received',
    'App not loading properly',
    'Other',
  ];
  String? _issue;
  final _details = TextEditingController();

  bool get _canSubmit => _issue != null;

  @override
  void initState() {
    super.initState();
    _details.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(children: [
            SizedBox(
              height: 99,
              child: Row(children: [
                const SizedBox(width: 24),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
                  child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, size: 20, color: _red), tooltip: 'Back'),
                ),
                const SizedBox(width: 10),
                const Text('Report Login Issue', style: TextStyle(color: Color(0xff13223c), fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Divider(height: 1, color: Color(0xffeeeeee)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
                    child: const Icon(Icons.mail_rounded, size: 28, color: _red),
                  ),
                  const SizedBox(height: 14),
                  const Text('What went wrong?', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff13223c), fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  const Text("Select the issue you're experiencing and describe it in\ndetail.", textAlign: TextAlign.center, style: TextStyle(color: Color(0xff53617a), fontSize: 12.5, height: 1.35)),
                  const SizedBox(height: 26),
                  const Text('Issue Type', style: TextStyle(color: Color(0xff13223c), fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ..._issues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _issue = issue),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 47,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xffdedfe4)), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Radio<String>(value: issue, groupValue: _issue, activeColor: _red, onChanged: (value) => setState(() => _issue = value)),
                            Expanded(child: Text(issue, style: const TextStyle(color: Color(0xff263651), fontSize: 14))),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text('Additional Details', style: TextStyle(color: Color(0xff13223c), fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _details,
                    minLines: 4,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe your issue in more detail...',
                      hintStyle: TextStyle(color: Color(0xff777984), fontSize: 14),
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.all(16),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xffdedfe4))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _red, width: 1.4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _canSubmit
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your report has been submitted.')));
                              Navigator.of(context).pop();
                            }
                          : null,
                      style: FilledButton.styleFrom(backgroundColor: _red, disabledBackgroundColor: const Color(0xffe49397), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Submit Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 40,
        child: TextButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xffcf2929),
            backgroundColor: const Color(0xffffe7eb),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
        ),
      );
}

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _red = Color(0xffcf2929);
  bool _checking = false;
  bool _resending = false;

  Future<void> _checkVerification() async {
    setState(() => _checking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        // Verification proves ownership of the email, but the user must now
        // explicitly sign in with the newly created account.
        await FirebaseAuth.instance.signOut();
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your email is not verified yet. Open the link, then try again.'),
        ));
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to check verification status.')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new verification link was sent.')),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to resend the verification email.')),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email address';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                minHeight: constraints.maxHeight - 56,
              ),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: Color(0xffffeef0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_rounded,
                        color: _red, size: 42),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Check your inbox',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xff202124),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'We sent a verification link to',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff6d6d75), fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8f8fa),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffe8e8ed)),
                    ),
                    child: Text(
                      email,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff303037),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xfffffbfb),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xffffe2e5)),
                    ),
                    child: const Column(children: [
                      _VerificationStep(number: '1', text: 'Open the email from LifeLink.'),
                      SizedBox(height: 14),
                      _VerificationStep(number: '2', text: 'Tap the verification link inside.'),
                      SizedBox(height: 14),
                      _VerificationStep(number: '3', text: 'Return here and confirm below.'),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _checking ? null : _checkVerification,
                      style: FilledButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _checking
                          ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                          : const Text('I\'ve verified my email', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    style: TextButton.styleFrom(foregroundColor: _red),
                    child: Text(_resending ? 'Sending verification link...' : 'Didn\'t get it? Resend email'),
                  ),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xff777780)),
                    child: const Text('Use a different account'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: _EmailVerificationScreenState._red, shape: BoxShape.circle),
            child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xff4f4f58), fontSize: 14, height: 1.25))),
        ],
      );
}

