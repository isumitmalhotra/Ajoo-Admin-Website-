import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A guest must never accept refund terms they were not shown.
///
/// Found by driving a real pre-booking on the emulator: the stay's
/// cancellation card read "We couldn't load the refund dates for this stay",
/// and the box saying "I have read and accept the cancellation policy for this
/// stay" sat directly beneath it, tickable. The endpoint served that exact
/// property and check-in date correctly moments later — so one dropped request
/// was enough, and nothing ever retried it. The message stayed until the
/// check-in date was changed, which is not something a guest would think to do.
///
/// Cancellation Policy v1.0 §15 requires the guest to see the policy, the
/// refund percentages and the important dates before paying, and to actively
/// acknowledge them. A tick collected over an error message satisfies "actively
/// acknowledge" and nothing else in that sentence.
///
/// The website's BookingReview had the identical gap; both were fixed together
/// and the web half is guarded by tests/cancellationScheduleFallback.test.mjs.
///
/// Read as source rather than pumped as a widget because the schedule comes
/// from a singleton service holding a real Dio — there is no seam to inject a
/// failure through, and inventing one to make this testable would be a larger
/// change than the fix.
void main() {
  final card = File(
    'lib/ui/screens_renter/property_details/widgets/stay_cancellation_card.dart',
  ).readAsStringSync();

  group('a failed schedule load', () {
    test('is retried before the guest is told anything', () {
      expect(
        card.contains('const backoff = [Duration.zero, Duration(milliseconds: 400), Duration(milliseconds: 1200)]'),
        isTrue,
        reason: 'one attempt is not enough — the failure that prompted this was '
            'transient, and the endpoint answered normally seconds later',
      );
    });

    test('can be retried by the guest without editing their dates', () {
      expect(card.contains("Text('Try again'"), isTrue,
          reason: 'the only escape from the error state used to be changing the '
              'check-in date');
      expect(RegExp(r'onTap: _load').hasMatch(card), isTrue,
          reason: 'and the control has to actually re-run the load');
    });

    test('makes the acknowledgement impossible, not merely discouraged', () {
      expect(card.contains('onChanged: _failed ? null :'), isTrue,
          reason: 'a disabled-looking checkbox that still accepts a tap collects '
              'the same consent it should be refusing');
      expect(card.contains('onTap: _failed ? null :'), isTrue,
          reason: 'the row wrapping the checkbox toggles it too — gating one and '
              'not the other leaves the box tickable by its label');
    });

    test('clears an acknowledgement given for the previous dates', () {
      expect(card.contains('if (widget.accepted) widget.onAccepted(false)'), isTrue,
          reason: 'otherwise a guest who accepted 20 Sep, changed to 22 Sep and '
              'hit a failure carries consent for a stay that no longer exists');
    });

    test('does not leave the previous stay\'s ladder on screen', () {
      final failBlock = card.substring(card.indexOf('setState(() {\n      // The OLD ladder'));
      expect(failBlock.contains('_schedule = null'), isTrue,
          reason: 'old deadlines beside new dates are worse than none: wrong, '
              'and they look right');
    });
  });
}
