import 'package:flutter/material.dart';

import '../app/lifelink_theme.dart';

class PasswordRule {
  const PasswordRule(this.label, this.isMet);

  final String label;
  final bool isMet;
}

abstract final class PasswordPolicy {
  static const minimumLength = 8;

  static List<PasswordRule> evaluate(String password) => [
    PasswordRule('At least 8 characters', password.length >= minimumLength),
    PasswordRule('One uppercase letter (A-Z)', RegExp(r'[A-Z]').hasMatch(password)),
    PasswordRule('One lowercase letter (a-z)', RegExp(r'[a-z]').hasMatch(password)),
    PasswordRule('One number (0-9)', RegExp(r'[0-9]').hasMatch(password)),
    PasswordRule(
      'One special character (e.g. !@#)',
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\;`~]').hasMatch(password),
    ),
  ];

  static bool isValid(String password) =>
      evaluate(password).every((rule) => rule.isMet);

  static String? validationMessage(String password) => isValid(password)
      ? null
      : 'Use at least 8 characters, including uppercase and lowercase letters, a number, and a special character.';
}

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final rule in PasswordPolicy.evaluate(password))
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: [
              Icon(
                rule.isMet
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 15,
                color: rule.isMet
                    ? const Color(0xff27824b)
                    : LifeLinkColors.muted,
              ),
              const SizedBox(width: 7),
              Text(
                rule.label,
                style: TextStyle(
                  color: rule.isMet
                      ? LifeLinkColors.ink
                      : LifeLinkColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
