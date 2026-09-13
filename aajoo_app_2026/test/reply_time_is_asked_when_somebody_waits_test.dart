import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

/// "How quickly do you usually reply?" is asked when somebody is waiting.
///
/// Asked 2026-09-13, looking at a listing set to **Fixed price only** and
/// **Instant Book**: why is this required, and is it used anywhere in that
/// case? It is not. Every consumer of `pbr_response_time_hours` is gated on one
/// of the two things that combination switches off —
///
///   negotiation threads          negotiation must be on
///   the property page rail       `requiresApproval ? … : …`
///   the payment page             `requiresApproval ? … : …`
///   the booking-confirmed page   the approval flow
///   the auto-confirm sweeper     skips anything not set to approval
///
/// — so a host wanting the simplest listing there is was blocked on a required
/// question about a situation their listing cannot produce.
///
/// The rule is enforced on the server. This file pins the APP's copy of it,
/// because a client that disagrees with the server either blocks a step the
/// API would have accepted, or lets a host through to a refusal they cannot
/// act on. Both have happened on this wizard before.
void main() {
  late ListingWizardController c;

  setUp(() {
    Get.testMode = true;
    c = ListingWizardController();
  });

  tearDown(Get.reset);

  group('somebody is waiting', () {
    test('a guest waiting on a price offer', () {
      c.p4['negotiation_enabled'] = true;
      c.p4['booking_type'] = 'instant';
      expect(c.responseTimeMatters, isTrue,
          reason: 'an offer is answered by the host, and the guest is shown '
              'how long that usually takes');
    });

    test('a guest waiting on an approval', () {
      c.p4['negotiation_enabled'] = false;
      c.p4['booking_type'] = 'approval';
      expect(c.responseTimeMatters, isTrue,
          reason: 'the sweeper that auto-confirms an ignored request reads '
              'this value, so on an approval listing it has real consequences');
    });

    test('both at once', () {
      c.p4['negotiation_enabled'] = true;
      c.p4['booking_type'] = 'approval';
      expect(c.responseTimeMatters, isTrue);
    });
  });

  group('nobody is waiting', () {
    test('fixed price and instant book', () {
      c.p4['negotiation_enabled'] = false;
      c.p4['booking_type'] = 'instant';
      expect(c.responseTimeMatters, isFalse,
          reason: 'this is the combination the client asked about — nothing on '
              'the platform will ever show a reply time for such a listing');
    });

    test('and the step saves without an answer', () {
      c.p4['negotiation_enabled'] = false;
      c.p4['booking_type'] = 'instant';
      c.p4.remove('response_time_hours');
      expect(c.validateStep4().containsKey('response_time_hours'), isFalse,
          reason: 'the host is blocked on a question their listing cannot ask');
    });
  });

  group('when it does apply it is still required', () {
    test('an offer listing with no answer is refused', () {
      c.p4['negotiation_enabled'] = true;
      c.p4['booking_type'] = 'instant';
      c.p4.remove('response_time_hours');
      expect(c.validateStep4()['response_time_hours'], isNotNull,
          reason: 'not defaulted, deliberately: 24 hours against a host who '
              'answers in one loses them the booking, and one hour against a '
              'host who answers tomorrow is a promise we made for them');
    });

    test('an approval listing with no answer is refused', () {
      c.p4['negotiation_enabled'] = false;
      c.p4['booking_type'] = 'approval';
      c.p4.remove('response_time_hours');
      expect(c.validateStep4()['response_time_hours'], isNotNull);
    });

    test('and an answered one is not', () {
      c.p4['negotiation_enabled'] = true;
      c.p4['booking_type'] = 'approval';
      c.p4['response_time_hours'] = '3';
      expect(c.validateStep4().containsKey('response_time_hours'), isFalse);
    });
  });

  group('the default is ON, and a draft from before the key existed reads null',
      () {
    test('null negotiation counts as allowed', () {
      // p4 starts with negotiation_enabled true, but a draft saved before that
      // key existed loads without it. `!= false` rather than `== true` because
      // the platform is negotiation-first: reading null as OFF would silently
      // stop asking a question those listings DO need answered.
      c.p4.remove('negotiation_enabled');
      c.p4['booking_type'] = 'instant';
      expect(c.responseTimeMatters, isTrue);
    });

    test('a missing booking type alone does not make it matter', () {
      c.p4['negotiation_enabled'] = false;
      c.p4.remove('booking_type');
      expect(c.responseTimeMatters, isFalse);
    });
  });
}
