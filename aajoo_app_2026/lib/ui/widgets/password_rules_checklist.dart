import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';

/// One rule a password must satisfy, as the backend enforces it.
class PasswordRule {
  final String label;
  final bool Function(String) test;
  const PasswordRule(this.label, this.test);
}

/// The password policy `POST /user/update-password` enforces
/// (backend schema/user.schema.js → updatePassword). Every surface that
/// CREATES a password shows this list, live — the user learns what the input
/// expects before Save, not from a rejection after it. Mirror the server
/// exactly: a rule shown here that the server doesn't check teaches people
/// requirements that don't exist, and a hidden one turns Save into a
/// surprise error.
final List<PasswordRule> kBackendPasswordRules = [
  PasswordRule('At least 8 characters', (v) => v.length >= 8),
  PasswordRule('An uppercase letter (A–Z)', (v) => RegExp(r'[A-Z]').hasMatch(v)),
  PasswordRule('A lowercase letter (a–z)', (v) => RegExp(r'[a-z]').hasMatch(v)),
  PasswordRule('A number (0–9)', (v) => RegExp(r'\d').hasMatch(v)),
  PasswordRule('A special character (!@#\$%… )',
      (v) => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)),
  PasswordRule('No spaces', (v) => v.isNotEmpty && !RegExp(r'\s').hasMatch(v)),
];

/// Form-validator twin of [kBackendPasswordRules] — same checks, one message
/// at a time, for screens that also want a red field error on submit.
String? validateAgainstPasswordRules(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password is required';
  for (final rule in kBackendPasswordRules) {
    if (!rule.test(v)) return 'Needs: ${rule.label.toLowerCase()}';
  }
  return null;
}

/// Live checklist that ticks each rule off as the password satisfies it.
/// Stateless on purpose — the caller decides how it hears about keystrokes
/// (ValueListenableBuilder over a TextEditingController, or Obx over an
/// RxString) and just rebuilds this with the current text.
class PasswordRulesChecklist extends StatelessWidget {
  final String password;
  const PasswordRulesChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your password must have:',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: kMuted),
          ),
          const SizedBox(height: 8),
          ...kBackendPasswordRules.map((rule) {
            final ok = rule.test(password);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: ok ? kSuccess : kMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: ok ? kSuccess : kMuted,
                        fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
