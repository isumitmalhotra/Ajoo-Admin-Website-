/// A negotiation is not rationed.
///
/// Client instruction, 2026-09-12: remove the three-counter system entirely —
/// unlimited counters. The app carried TWO separate allowances, and the
/// tighter one was not the one anybody was talking about:
///
///   the REST offers list showed "N of your 3 offers left", and its model
///     defaulted maxRounds to 3 whenever the server omitted it — so removing
///     the field server-side would have left the app still counting down from
///     a number nothing sent
///
///   the socket chat screen capped at TWO messages per side, client-side only,
///     and refused the third send itself
///
/// The first of those is the trap worth a test: a default of 3 in a `fromJson`
/// is invisible from the server, and the screen would have gone on promising
/// an allowance that no longer existed.
///
///   flutter test test/counters_are_not_rationed_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/guest_negotiation.dart';
import 'package:rent_home/models/host_negotiation.dart';

void main() {
  group('no allowance survives in the models', () {
    test('a guest thread four rounds in is still answerable', () {
      final n = GuestNegotiation.fromJson({
        'offerId': 8,
        'propertyId': 29303,
        'propertyName': 'Sea Breeze',
        'status': 'awaiting_you',
        'awaitingYou': true,
        'actionableOfferId': 8,
        'canCounter': true,
        'roundsYou': 4,
        'latestPrice': 4200,
        'listedPrice': 5000,
      });

      expect(n.canCounter, isTrue,
          reason: 'the guest is out of offers after four rounds — an '
              'allowance is still being enforced somewhere');
      expect(n.roundsYou, 4, reason: 'the count is still worth reporting');
    });

    test('the model has no maxRounds to count down from', () {
      // The defaulted field is the trap: `maxRounds: j['maxRounds'] == null
      // ? 3 : ...` meant the server could stop sending it and every screen
      // would carry on subtracting from three, with nothing to notice.
      final n = GuestNegotiation.fromJson({
        'offerId': 1,
        'propertyId': 1,
        'propertyName': 'x',
        'status': 'awaiting_you',
        'roundsYou': 2,
      });
      expect(() => (n as dynamic).maxRounds, throwsNoSuchMethodError,
          reason: 'maxRounds is still on the model, so a screen can still '
              'render "N of your 3 offers left"');
    });

    test('the host card says which round it is, not how many are left', () {
      final h = HostNegotiation.fromJson({
        'offerId': 9,
        'propertyId': 29303,
        'propertyName': 'Sea Breeze',
        'guestName': 'Aajoo Renter',
        'offerPrice': 4000,
        'listedPrice': 5000,
        'status': 'pending',
        'messages': [
          {'price': 3000},
          {'price': 4600},
          {'price': 3400},
          {'price': 4400},
        ],
      });

      expect(h.roundLabel, isNotNull);
      expect(h.roundLabel, isNot(contains(' of ')),
          reason: 'the label still names a ceiling — "Round 2 of 3" promises '
              'an allowance that was removed');
      expect(h.roundLabel, contains('Round'));
    });

    test('nothing exchanged yet has no round label at all', () {
      final h = HostNegotiation.fromJson({
        'offerId': 9,
        'propertyId': 1,
        'propertyName': 'x',
        'guestName': 'y',
        'offerPrice': 1,
        'listedPrice': 2,
        'status': 'pending',
        'messages': const [],
      });
      expect(h.roundLabel, isNull);
    });
  });
}
