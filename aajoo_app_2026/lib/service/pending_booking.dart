import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/service_log.dart';

/// The booking a guest was in the middle of when something took them out of
/// the app.
///
/// KYC is the case that matters. Tapping Book Now or Negotiate without a
/// verified ID sends the guest to DIDIT, which opens in the SYSTEM BROWSER —
/// camera access does not work reliably in an in-app webview, so this is
/// deliberate. But leaving the app means Android is free to destroy the
/// activity while the guest is in Chrome, and when they come back Flutter
/// starts at the initial route with an empty navigation stack. The property
/// page, the dates they picked, the coupon they entered: all gone. They did
/// exactly what the app asked and landed on the home screen with nothing to
/// show for it.
///
/// So the intent is written to disk before the app hands control away, and the
/// home screen offers to pick it up again.
class PendingBooking {
  final int propertyId;
  final String propertyName;

  /// DD-MM-YYYY, matching what the booking API takes.
  final String? bookFrom;
  final String? bookTo;
  final String? couponCode;
  final bool isCod;
  final DateTime savedAt;

  /// How many people the stay was for. 0 = never chosen. Restored on resume
  /// because the price now depends on it — a listing that charges beyond an
  /// included headcount would re-quote a resumed booking for a party of one.
  final int guests;

  const PendingBooking({
    required this.propertyId,
    required this.propertyName,
    required this.savedAt,
    this.bookFrom,
    this.bookTo,
    this.couponCode,
    this.isCod = false,
    this.guests = 0,
  });

  /// Dates go stale. A week-old intent is more likely to confuse than help,
  /// and the dates may since have been booked by somebody else.
  bool get isFresh => DateTime.now().difference(savedAt) < const Duration(days: 2);

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'propertyName': propertyName,
        'bookFrom': bookFrom,
        'bookTo': bookTo,
        'couponCode': couponCode,
        'isCod': isCod,
        'guests': guests,
        'savedAt': savedAt.toIso8601String(),
      };

  static PendingBooking? fromJson(Map<String, dynamic> j) {
    final id = (j['propertyId'] as num?)?.toInt();
    if (id == null || id == 0) return null;
    return PendingBooking(
      propertyId: id,
      propertyName: (j['propertyName'] ?? '').toString(),
      bookFrom: j['bookFrom']?.toString(),
      bookTo: j['bookTo']?.toString(),
      couponCode: j['couponCode']?.toString(),
      isCod: j['isCod'] == true,
      guests: (j['guests'] as num?)?.toInt() ?? 0,
      savedAt: DateTime.tryParse(j['savedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class PendingBookingStore {
  static const _key = 'aajoo.pending_booking';
  // The app already ships flutter_secure_storage for the auth token, so this
  // adds no dependency. Nothing here is secret, only worth surviving a restart.
  static const _storage = FlutterSecureStorage();

  /// Never throws: failing to remember a booking must not break the flow that
  /// was about to leave for verification.
  static Future<void> save(PendingBooking intent) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(intent.toJson()));
    } catch (_) {}
  }

  static Future<PendingBooking?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final intent = PendingBooking.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      if (intent == null || !intent.isFresh) {
        await clear();
        return null;
      }
      return intent;
    } catch (e) {
      logServiceError('pending_booking:102', e);
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
