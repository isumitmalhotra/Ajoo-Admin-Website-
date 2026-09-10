import 'package:flutter_test/flutter_test.dart';
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
