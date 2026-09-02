import 'package:flutter/material.dart';

import '../app/app_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _red = Color(0xffcf2929);
  bool _signUp = false;
  bool _verify = false;
  bool _obscurePassword = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _continue() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password.')),
      );
      return;
    }
    if (_signUp && !_verify) {
      setState(() => _verify = true);
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  InputDecoration _field({required String hint, Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff777984), fontSize: 14),
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xffdedfe4))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _red, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    if (_verify) return _VerificationPage(email: _email.text, onVerify: _continue);
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
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _field(hint: 'Email')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: _field(
                          hint: 'Password',
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
                              MaterialPageRoute(builder: (_) => const _ForgotPasswordPage()),
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
                          onPressed: _continue,
                          style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(_signUp ? 'Sign up' : 'Log in', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

class _CreateAccountPage extends StatefulWidget {
  const _CreateAccountPage();

  @override
  State<_CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<_CreateAccountPage> {
  static const _red = Color(0xffcf2929);
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _bloodType;
  bool _bloodMenuOpen = false;
  bool _agreed = false;
  bool _obscurePassword = true;

  bool get _canCreate =>
      _agreed &&
      _firstName.text.trim().isNotEmpty &&
      _lastName.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _bloodType != null &&
      _password.text.isNotEmpty &&
      _password.text == _confirmPassword.text;

  @override
  void initState() {
    super.initState();
    for (final controller in [_firstName, _lastName, _email, _phone, _password, _confirmPassword]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _email, _phone, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _field(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff777984), fontSize: 14),
        suffixIcon: suffix,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xffdedfe4))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _red, width: 1.4)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: Color(0xff13223c), fontSize: 14, fontWeight: FontWeight.w500))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(children: [
            SizedBox(
              height: 92,
              child: Row(children: [
                const SizedBox(width: 30),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
                  child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, size: 20, color: _red), tooltip: 'Back'),
                ),
                const SizedBox(width: 12),
                const Text('Create Account', style: TextStyle(color: Color(0xff13223c), fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Divider(height: 1, color: Color(0xffeeeeee)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(38, 22, 38, 30),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('First Name'), TextField(controller: _firstName, decoration: _field('First Name'))])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Last Name'), TextField(controller: _lastName, decoration: _field('Last Name'))])),
                  ]),
                  const SizedBox(height: 17),
                  _label('Email Address'),
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _field('example@gmail.com')),
                  const SizedBox(height: 17),
                  _label('Phone Number'),
                  TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: _field('09xx xxx xxxx')),
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
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xffdedfe4)), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Expanded(child: Text(_bloodType ?? 'Select blood type', style: TextStyle(color: _bloodType == null ? Colors.black : const Color(0xff13223c), fontSize: 14))),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 22),
                        ]),
                      ),
                    ),
                  ),
                  if (_bloodMenuOpen)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xffdedfe4))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: const Color(0xff777777),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: const Text('Select blood type', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          ...['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map(
                            (type) => InkWell(
                              onTap: () => setState(() {
                                _bloodType = type;
                                _bloodMenuOpen = false;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Text(type, style: const TextStyle(color: Colors.black, fontSize: 14)),
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
                    decoration: _field('Create a password', suffix: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: _red, size: 20))),
                  ),
                  const SizedBox(height: 17),
                  _label('Confirm Password'),
                  TextField(controller: _confirmPassword, obscureText: true, decoration: _field('Re-enter password')),
                  const SizedBox(height: 10),
                  Row(children: [
                    Checkbox(value: _agreed, onChanged: (value) => setState(() => _agreed = value ?? false), activeColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                    Expanded(child: RichText(text: const TextSpan(style: TextStyle(color: Color(0xff53617a), fontSize: 12.5), children: [TextSpan(text: 'I agree to the '), TextSpan(text: 'Terms of Service', style: TextStyle(color: _red, fontWeight: FontWeight.w700)), TextSpan(text: ' and '), TextSpan(text: 'Privacy Policy', style: TextStyle(color: _red, fontWeight: FontWeight.w700))]))),
                  ]),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 49,
                    child: FilledButton(
                      onPressed: _canCreate ? () => Navigator.of(context).pop() : null,
                      style: FilledButton.styleFrom(backgroundColor: _red, disabledBackgroundColor: const Color(0xffe49397), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
                          TextSpan(text: 'Log In', style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _ForgotPasswordPage extends StatefulWidget {
  const _ForgotPasswordPage();

  @override
  State<_ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<_ForgotPasswordPage> {
  static const _red = Color(0xffcf2929);
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email address.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verification code sent to ${_email.text.trim()}.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(children: [
            SizedBox(
              height: 94,
              child: Row(children: [
                const SizedBox(width: 15),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 20, color: _red),
                    tooltip: 'Back',
                  ),
                ),
                const SizedBox(width: 9),
                const Text('Forgot Password', style: TextStyle(color: Color(0xff13223c), fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Divider(height: 1, color: Color(0xffeeeeee)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 33, 22, 24),
                child: Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Color(0xffffe7eb), shape: BoxShape.circle),
                    child: const Icon(Icons.mail_rounded, size: 29, color: _red),
                  ),
                  const SizedBox(height: 20),
                  const Text('Reset Password', style: TextStyle(color: Color(0xff13223c), fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  const Text(
                    "Enter your registered email and we'll send you a\nverification code.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff53617a), fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 34),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Email Address', style: TextStyle(color: Color(0xff13223c), fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 11),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(color: Color(0xff777984), fontSize: 14),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xffdedfe4))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _red, width: 1.4)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 53,
                    child: FilledButton(
                      onPressed: _sendCode,
                      style: FilledButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Send Verification Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

class _VerificationPage extends StatelessWidget {
  const _VerificationPage({required this.email, required this.onVerify});
  final String email;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.mark_email_read_outlined, color: Color(0xffcf2929), size: 56),
          const SizedBox(height: 24),
          const Text('Verify your email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('We sent a verification code to $email.', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          TextField(keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: 'Verification code', counterText: '', suffixIcon: TextButton(onPressed: () {}, child: const Text('Resend')))),
          const SizedBox(height: 18),
          FilledButton(onPressed: onVerify, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: const Color(0xffcf2929)), child: const Text('Verify & Create Account')),
        ]),
      );
}
