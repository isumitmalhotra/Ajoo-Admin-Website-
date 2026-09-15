/// Rupees, formatted the way India reads them.
///
/// The Indian grouping is not the western one: the last three digits are one
/// group, and everything above that is grouped in PAIRS — 1,00,000 rather than
/// 100,000. `intl`'s en_IN locale does this, but pulling a locale in for one
/// number means initialising locale data at startup, so the rule is written
/// out here.
///
/// This exists because prices reached the screen in whatever shape the API
/// sent: a map pin read "₹3200.00" and a booking total read "₹2100", next to a
/// web card reading "₹3,200". Same number, three renderings.
library;

/// Whole rupees with Indian digit grouping, no symbol: `3200.0` -> `"3,200"`.
///
/// Rounds to whole rupees — paise are never shown anywhere in the product.
String rupeeDigits(num value) {
  if (!value.isFinite) return '0';
  final negative = value < 0;
  final digits = value.round().abs().toString();

  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final pairs = <String>[];
    while (rest.length > 2) {
      pairs.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) pairs.insert(0, rest);
    grouped = '${pairs.join(',')},$last3';
  }
  return negative ? '-$grouped' : grouped;
}

/// The same, with the symbol: `3200.0` -> `"₹3,200"`.
String rupees(num value) => '₹${rupeeDigits(value)}';

/// Rupees with paise only when there are paise: ₹18,898.95, ₹27,376.
///
/// For the figures the gateway will show — a total, its tax, its discount.
/// "₹18,899" on the sheet and "₹18,898.95" on the Razorpay screen is the
/// difference the client reported on the website ("during payment the
/// price is again different"); the app rounded the same way. Two places or
/// none, never one.
String rupeesExact(num value) {
  if (!value.isFinite) return '₹0';
  final whole = (value - value.roundToDouble()).abs() < 0.005;
  if (whole) return rupees(value);
  final paise = ((value.abs() * 100).roundToDouble() % 100).round();
  final units = value.abs().floor() * (value < 0 ? -1 : 1);
  return '${rupees(units)}.${paise.toString().padLeft(2, '0')}';
}

/// Parse whatever the API sent — `"3200.00"`, `"₹3,200"`, `3200` — and format
/// it. Returns the cleaned input unchanged when it is not a number at all, so
/// an odd shape can never render as a blank price.
String rupeesFrom(Object? raw) {
  if (raw == null) return '';
  if (raw is num) return rupees(raw);
  final cleaned = raw.toString().replaceAll('₹', '').replaceAll(',', '').trim();
  final value = double.tryParse(cleaned);
  return value == null ? cleaned : rupees(value);
}
