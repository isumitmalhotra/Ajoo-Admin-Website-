// Keystroke sanitizers — the app-side twin of the web's `filters` in
// formErrors.ts. A validator answers "is this value acceptable?" at submit;
// these answer "can this character ever appear in this field?" at typing time.
// A name can never contain a digit, a phone can never contain a letter —
// dropping the impossible character as it is typed is what makes a field feel
// certain instead of tolerated-until-submit.
//
// Wire as:  inputFormatters: AppInputFormatters.name
// (each getter returns a fresh list so callers can append field-specific ones)
import 'package:flutter/services.dart';

class AppInputFormatters {
  AppInputFormatters._();

  /// Person names: letters, spaces, dot, apostrophe, hyphen. No digits ever.
  static List<TextInputFormatter> get name => [
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'’-]")),
        LengthLimitingTextInputFormatter(100),
      ];

  /// Place names (city/town/locality): letters + a few separators.
  static List<TextInputFormatter> get place => [
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'’()&-]")),
        LengthLimitingTextInputFormatter(80),
      ];

  /// Digits only with a hard cap — OTPs, account numbers, counts.
  static List<TextInputFormatter> digits(int max) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(max),
      ];

  /// Indian mobile: 10 digits, tolerant of a pasted +91 or a trunk 0.
  ///
  /// Plain digitsOnly + a 10-char cap silently turns "+91 98765 43210" into
  /// "9198765432" — still ten digits, still passes the validator, and the
  /// wrong number. The prefix is dropped only once the value is too long to
  /// be a bare mobile, because 9198765432 IS a valid number and typing it
  /// must not have its own first two digits eaten.
  static List<TextInputFormatter> get mobile => [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          var d = newValue.text;
          if (d.length > 10 && d.startsWith('91')) d = d.substring(2);
          if (d.length > 10 && d.startsWith('0')) {
            d = d.replaceFirst(RegExp(r'^0+'), '');
          }
          if (d.length > 10) d = d.substring(0, 10);
          return d == newValue.text
              ? newValue
              : TextEditingValue(
                  text: d,
                  selection: TextSelection.collapsed(offset: d.length),
                );
        }),
      ];

  /// PIN code: 6 digits.
  static List<TextInputFormatter> get pincode => digits(6);

  /// Money/quantity: digits and at most one decimal point.
  static List<TextInputFormatter> get amount => [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        TextInputFormatter.withFunction((oldValue, newValue) =>
            '.'.allMatches(newValue.text).length > 1 ? oldValue : newValue),
      ];

  /// Uppercase alphanumeric with cap — IFSC (11), PAN (10), doc numbers.
  static List<TextInputFormatter> upperAlnum(int max) => [
        TextInputFormatter.withFunction((oldValue, newValue) =>
            newValue.copyWith(text: newValue.text.toUpperCase())),
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        LengthLimitingTextInputFormatter(max),
      ];

  /// Email typing: everything except whitespace (format checked at submit).
  static List<TextInputFormatter> get email => [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ];
}
