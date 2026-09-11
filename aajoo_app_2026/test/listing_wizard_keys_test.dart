import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// The wizard's field keys ARE the contract, in both directions.
///
/// The save endpoint reads `req.body.<key>`, and the draft loader fills the
/// form back in by stripping the column prefix — `pbr_min_stay_nights` becomes
/// `min_stay_nights`, `ppr_extra_guest_price` becomes `extra_guest_price`. So a
/// form field named anything else is broken twice over: the host's answer is
/// posted and silently dropped, and the control is empty again next time they
/// open the listing. Nothing errors. Nothing logs. The host simply retypes it,
/// which is exactly what was reported — "data still not updating even after
/// updating multiple times".
///
/// This had happened FOUR times on one step before anyone wrote a test:
///
///   response_time  → response_time_hours    (fixed, comment left in place)
///   min_nights     → min_stay_nights        (found 2026-09-09)
///   max_nights     → max_stay_nights        (found 2026-09-09)
///   extra_guest_fee → extra_guest_price     (found 2026-09-09 — the charge
///                                            was NULL on every listing in the
///                                            database)
///
/// and two fields the app never asked for at all (checkin_time, checkout_time)
/// while the website had asked for both since the wizard shipped.
///
/// The min/max one was not merely cosmetic: with no limit ever stored, booking
/// had nothing to enforce and accepted a one-night stay on a property whose
/// host had set a three-night minimum.
///
/// So this test holds the app's keys against the server's. The reference list
/// below is every `b.<key>` read by saveStep4 in the backend's
/// controllers/listingEngine.controller.js. When the server learns a new field,
/// add it here; when this test fails, one side has been renamed without the
/// other and a host's answer is about to start disappearing.
void main() {
  /// Every key `saveStep4` reads from the request body.
  /// Source: aajaoBackend-render/controllers/listingEngine.controller.js
  const serverReads = <String>{
    'advance_booking_discount', 'alcohol', 'auto_accept_above',
    'auto_reject_below', 'availability', 'bank_verified', 'base_price',
    'booking_type', 'cancellation_policy', 'cancellation_tiers',
    'caretaker_available', 'charge_extra_guests', 'checkin_time',
    'checkout_time', 'child_age_group', 'child_price', 'children_free',
    'cleaning_fee', 'cleaning_fee_type', 'commercial_shoot',
    'compensation_rules', 'cooking_allowed', 'counter_offer_allowed',
    'currency', 'custom_stay_discount', 'damage_deposit', 'damage_reporting',
    'deposit_refundable', 'early_checkin', 'extra_guest_price',
    'friday_price', 'guests_included', 'host_message', 'late_checkin',
    'late_checkout', 'loud_music', 'max_advance_days', 'max_attempts',
    'max_extra_guests', 'max_negotiation_percent', 'max_pets',
    'max_stay_nights', 'min_stay_nights', 'minimum_notice_hours',
    'monthly_discount', 'monthly_ideal_price', 'monthly_minimum_price',
    'monthly_price', 'negotiation_enabled', 'negotiation_expiry_hours',
    'negotiation_ideal_price', 'negotiation_minimum_price', 'open_months',
    'parties', 'payout_cycle', 'pet_fee', 'pet_size', 'pets_allowed',
    'property_id', 'quiet_hours', 'rate_periods', 'response_time_hours',
    'same_day_booking', 'saturday_price', 'security_deposit', 'self_checkin',
    'self_checkin_method', 'smoking', 'sunday_price', 'tax_exclusive',
    'visitors', 'weekend_ideal_price', 'weekend_minimum_price',
    'weekend_pricing', 'weekly_discount', 'weekly_ideal_price',
    'weekly_minimum_price', 'weekly_price',
  };

  final source = File(
    'lib/ui/screens_host/listing/listing_wizard_screen.dart',
  ).readAsStringSync();

  /// Every key the step sends, however it is written.
  ///
  /// Both the _p4Text/_p4Choice/_p4Toggle helpers AND direct setP4 calls — the
  /// month picker sets its value straight through setP4, and a guard that knew
  /// only about the helpers would wave the next such field past without
  /// looking.
  ///
  /// Raw strings and concatenation, not interpolation: the escapes in this
  /// pattern have been mangled twice by the tooling that wrote this file, and
  /// a broken regex here fails open — it finds no keys and every check passes.
  Set<String> keysFor(String prefix) => {
        // `Time` joined the list on 2026-09-11, when check-in and check-out
        // stopped being free-text boxes and became a picker. The behaviour was
        // better and this scan said the fields had vanished — the hazard of
        // asking the source how it asks rather than what it asks for.
        ...RegExp('_' + prefix + r"(?:Text|Choice|Toggle|Time)\('([a-z0-9_]+)'")
            .allMatches(source)
            .map((m) => m.group(1)!),
        ...RegExp('setP' + prefix.substring(1) + r"\('([a-z0-9_]+)'")
            .allMatches(source)
            .map((m) => m.group(1)!),
      };

  test('the app can price a weekend at all, and negotiate it', () {
    // Until 2026-09-10 this wizard had NO weekend pricing: not the rates, not
    // the toggle. The website had asked for Friday/Saturday/Sunday since it
    // shipped, so a host who listed from their phone simply could not charge
    // more at the weekend — and once the weekend negotiation ladder existed,
    // could not set that either, while the engine read the columns all along.
    final appKeys = keysFor('p4');
    for (final key in [
      'weekend_pricing',
      'friday_price',
      'saturday_price',
      'sunday_price',
      'weekend_minimum_price',
      'weekend_ideal_price',
    ]) {
      expect(appKeys, contains(key),
          reason: 'the app cannot set $key, so the website and the phone '
              'produce different listings from the same wizard');
    }
  });

  test('every step-4 key the app sends is one the server reads', () {
    final appKeys = keysFor('p4');
    expect(appKeys, isNotEmpty, reason: 'the extractor stopped matching — fix it before trusting a pass');

    final dropped = appKeys.difference(serverReads).toList()..sort();
    expect(
      dropped,
      isEmpty,
      reason: 'these keys are posted and silently discarded by saveStep4, and '
          'the draft loader can never fill them back in: $dropped',
    );
  });

  test('the fields that were being dropped are asked for, under the right names', () {
    final appKeys = keysFor('p4');
    for (final k in [
      'min_stay_nights',
      'max_stay_nights',
      'extra_guest_price',
      'response_time_hours',
      // Never asked for on the app at all until 2026-09-09, so a host who
      // listed from their phone left every screen showing a dash for these.
      'checkin_time',
      'checkout_time',
      // The follow-up question "Seasonal" never had. Set through setP4 rather
      // than a _p4 helper, which is why the extractor above reads both.
      'open_months',
    ]) {
      expect(appKeys, contains(k), reason: '$k is not asked for on step 4');
    }
  });

  /// Every key `saveStep5` reads from the request body.
  /// Source: aajaoBackend-render/controllers/listingStep5.controller.js
  const step5ServerReads = <String>{
    'account_holder', 'account_number', 'authorization_doc', 'bank_name',
    'cancelled_cheque', 'caretaker_available', 'caretaker_hours',
    'caretaker_languages', 'caretaker_name', 'caretaker_phone',
    'commercial_property', 'declaration_host_agreement',
    'emergency_available_24x7', 'emergency_name', 'emergency_phone',
    'emergency_relationship', 'fire_safety', 'government_registration',
    'gst_number', 'gst_registered', 'identity_doc', 'identity_number',
    'identity_type', 'ifsc', 'insurance', 'local_authority_approval',
    'ownership_doc', 'ownership_doc_type', 'property_id', 'selfie_url',
    'upi_id',
  };

  test('every step-5 key the app sends is one the server reads', () {
    // The fifth time (2026-09-11): 'account_holder_name'. A new host filed a
    // listing from the phone, typed their name over the bank account, and
    // the bank row was saved with a blank holder — the server reads
    // 'account_holder', which is also what the website sends and what the
    // draft loader hands back. The step-4 guard above had been in place for
    // two days and did not look at step 5.
    final appKeys = keysFor('p5');
    expect(appKeys, isNotEmpty, reason: 'the extractor stopped matching — fix it before trusting a pass');
    final dropped = appKeys.difference(step5ServerReads).toList()..sort();
    expect(
      dropped,
      isEmpty,
      reason: 'these keys are posted and silently discarded by saveStep5: $dropped',
    );
    expect(appKeys, contains('account_holder'));
  });

  test('the old names are gone, not merely joined by the new ones', () {
    final appKeys = keysFor('p4');
    for (final dead in [
      'min_nights',
      'max_nights',
      'extra_guest_fee',
      'response_time',
    ]) {
      expect(appKeys, isNot(contains(dead)),
          reason: '$dead is a name the server has never read');
    }
    expect(keysFor('p5'), isNot(contains('account_holder_name')),
        reason: 'account_holder_name is a name the server has never read');
  });
}
