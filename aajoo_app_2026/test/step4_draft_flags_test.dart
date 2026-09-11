import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

/// The two switches on step 4 must come back saying what is on file.
///
/// Found on the emulator on 2026-09-10 while testing the Photos gate: opening
/// a real listing and pressing Continue on step 4 was refused with "Weekend
/// minimum is required, and must be more than zero." — for a screen whose
/// weekend section was not even showing, because its switch read OFF.
///
/// Both faults are the draft speaking in COLUMNS while the form speaks in
/// FIELDS, which is bug 25 all over again in a step nobody re-checked:
///
///   1. `ppr_weekend_pricing` arrives as MySQL's 1, and every read of it is
///      `== true`. The switch rendered off, the whole of p4 was posted back
///      with the 1 still in it, and the server — which reads it as ON —
///      demanded a weekend minimum for a section the screen was hiding. Step 4
///      could not be saved from the app at all.
///   2. `pn_enabled` strips to `enabled`, and both the switch and the save
///      payload use `negotiation_enabled`. So the switch read null and
///      rendered ON (it tests `!= false`), the key was absent from every save,
///      and listingEngine.controller defaults a missing negotiation_enabled to
///      1. Editing ANY listing from the app turned negotiation back on for a
///      host who had switched it off — silently, with the switch showing on
///      the whole time.
void main() {
  ListingWizardController wizard(Map<String, dynamic> draft) =>
      ListingWizardController(propertyId: 77, service: _StubService(draft));

  test('a listing that prices weekends apart opens with the switch ON',
      () async {
    final c = wizard({
      'pricing': {
        'ppr_base_price': 2000,
        'ppr_weekend_pricing': 1, // MySQL true
        'ppr_friday_price': 3000,
        'ppr_weekend_min': 2500,
        'ppr_weekend_ideal': 2800,
      },
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);

    expect(c.p4['weekend_pricing'], isTrue,
        reason: 'the switch reads `== true`, so a stored 1 renders OFF and '
            'the weekend prices below it are hidden');

    // THE ONE THAT MATTERS: with the flag coerced, the step validates against
    // the same rule the server applies instead of being refused for a field
    // the host cannot see.
    c.step.value = 3;
    // Only the weekend rules are this test's business — the fixture leaves
    // the weekly and monthly tiers out, and those have their own errors.
    expect(c.validateStep4().keys.where((k) => k.startsWith('weekend')), isEmpty,
        reason: 'a complete weekend pair is still being rejected');
  });

  test('a listing with weekends off stays off', () async {
    final c = wizard({
      'pricing': {'ppr_base_price': 2000, 'ppr_weekend_pricing': 0},
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.p4['weekend_pricing'], isFalse);
  });

  test('a host who switched negotiation OFF finds it off', () async {
    final c = wizard({
      'pricing': {'ppr_base_price': 2000},
      'negotiation': {'pn_enabled': 0},
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);

    // The switch tests `!= false`, so anything but a real false shows ON — and
    // saving then posts nothing, which the server reads as "enable it".
    expect(c.p4['negotiation_enabled'], isFalse,
        reason: 'editing this listing would turn negotiation back on, and the '
            'switch would show on while it happened');
  });

  test('the cancellation policy comes back selected', () async {
    // Stored on the FLAT property row as property_cancellation_policy, while
    // the chips and the save endpoint both say cancellation_policy. Unmapped,
    // step 4 drew Flexible / Moderate / Firm / Strict with none selected on a
    // listing that has a policy — and a host who "fixes" that by picking one
    // changes what their guests are owed. Seen on 29291, which stores
    // "flexible", on 2026-09-11.
    final c = wizard({
      'pricing': {'ppr_base_price': 2000},
      'property': {'property_cancellation_policy': 'flexible'},
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.p4['cancellation_policy'], 'flexible',
        reason: 'the chips render with nothing selected on a listing that has '
            'a cancellation policy');
  });

  test('a listing with no policy on file selects nothing', () async {
    final c = wizard({'pricing': {'ppr_base_price': 2000}, 'property': {}});
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.p4['cancellation_policy'], isNull,
        reason: 'a policy was invented for a listing that has none');
  });

  test('the cancellation policy is REQUIRED', () async {
    // Client's rule, 2026-09-11. A listing without one had guests reading
    // "the host hasn't set a cancellation policy yet" on the booking page,
    // and the policy decides what they are owed when they cancel. The server
    // refuses the step and the publication; this is the app saying so on the
    // chips, before the round trip.
    final c = wizard({'pricing': {'ppr_base_price': 2000}, 'property': {}});
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    c.step.value = 3;
    expect(c.validateStep4()['cancellation_policy'], isNotNull,
        reason: 'step 4 lets a host continue with no cancellation policy');

    c.setP4('cancellation_policy', 'moderate');
    expect(c.validateStep4()['cancellation_policy'], isNull,
        reason: 'a chosen policy is still being refused');
  });

  test('the server verdict gates Submit, and the reason is shown', () {
    final c = ListingWizardController(propertyId: 77, service: _StubService({}));
    // Not loaded yet: do not stand in the way — the server has the last word.
    expect(c.serverAllowsSubmit, isTrue);
    expect(c.blockedReason, isNull);

    c.readiness.assignAll({
      'canSubmit': false,
      'blockedReason': 'Before publishing, upload your identity document.',
    });
    expect(c.serverAllowsSubmit, isFalse,
        reason: 'the button stays green on a listing the server will refuse');
    expect(c.blockedReason, contains('identity document'),
        reason: 'the host is not told why the button is grey');

    c.readiness.assignAll({'canSubmit': true, 'blockedReason': null});
    expect(c.serverAllowsSubmit, isTrue);
    expect(c.blockedReason, isNull);
  });

  test('the extra-guest switch comes back on, and the fee needs a base', () async {
    // The app asked for the extra guest FEE alone; the pricing engine charges
    // it only when charge_extra_guests is on and guests_included says who is
    // extra. Neither was ever sent, so a ₹400 fee reached nobody (29302,
    // six guests, fee 0 — 2026-09-11). The section now matches the website.
    final c = wizard({
      'pricing': {
        'ppr_base_price': 2000,
        'ppr_charge_extra_guests': 1, // MySQL true
        'ppr_guests_included': 4,
        'ppr_extra_guest_price': 400,
        'ppr_children_free': 0,
      },
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.p4['charge_extra_guests'], isTrue,
        reason: 'a stored 1 renders the switch OFF and hides the fee');
    expect(c.p4['children_free'], isFalse);

    // A fee with nobody to charge it to is refused before the save.
    c.step.value = 3;
    c.setP4('guests_included', '');
    expect(c.validateStep4()['guests_included'], isNotNull,
        reason: 'a fee is accepted with no guests_included — the engine will charge nobody');
    c.setP4('guests_included', '4');
    expect(c.validateStep4()['guests_included'], isNull);
  });

  test('the self check-in method comes back chosen, and is not saved over',
      () async {
    // Stored on the house-rules row (phr_self_checkin_method), which the
    // loader merged into p5; the chip is on step 4 and reads p4. It rendered
    // unchosen on a listing that had "keypad" on file, and the next save of
    // step 4 — which posts the whole of p4 — wrote NULL over it.
    final c = wizard({
      'pricing': {'ppr_base_price': 2000},
      'houseRules': {'phr_self_checkin': 1, 'phr_self_checkin_method': 'keypad'},
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.p4['self_checkin_method'], 'keypad',
        reason: 'the chip reads p4; the value landed only in p5, so the '
            'host sees nothing chosen and the next save erases it');
  });

  test('a host who left negotiation ON keeps it on', () async {
    final c = wizard({
      'pricing': {'ppr_base_price': 2000},
      'negotiation': {'pn_enabled': 1},
    });
    c.onInit();
    await Future<void>.delayed(Duration.zero);
    expect(c.p4['negotiation_enabled'], isTrue);
  });
}

class _StubService extends ListingService {
  _StubService(this.draft);

  final Map<String, dynamic> draft;

  @override
  Future<ListingSchema> getSchema({bool refresh = false}) async =>
      ListingSchema.fromJson({
        'pricingRules': {'minBasePrice': 100, 'maxBasePrice': 100000},
      });

  @override
  Future<Map<String, dynamic>> getDraft(int propertyId) async => draft;
}
