// One labelling rule, four screens.
//
// A status describes what happened TO a message, not what its sender did —
// whoever ACTS on an offer is always the other side from whoever SENT it. Read
// the other way round, a renter whose offer the host had declined was shown
// "You declined ₹650" on their own screen, at the end of the one thread that
// needed to explain itself. Reported from the live site on 2026-09-12.
//
// The website's two negotiation screens ask one shared function; these are the
// same cases, so the phone and the laptop cannot drift the way they did for a
// fortnight over whose move it was.
//
//   flutter test test/transcript_label_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/host_negotiation.dart';
import 'package:rent_home/utils/transcript_label.dart';

String guest(bool mine, String status) => transcriptLabel(
    mine: mine, status: status, viewer: TranscriptViewer.guest);

String host(bool mine, String status, {bool automatic = false}) =>
    transcriptLabel(
        mine: mine,
        status: status,
        viewer: TranscriptViewer.host,
        automatic: automatic);

void main() {
  group("the guest's screen", () {
    test('a status says what was done TO your message, not what you did', () {
      expect(guest(true, 'declined'), 'Your offer was declined',
          reason: 'the guest is told they declined their own offer');
      expect(guest(true, 'accepted'), 'Your offer was accepted');
      expect(guest(true, 'expired'), 'Your offer expired');
      expect(guest(true, 'countered'), 'You offered');
    });

    test("an acceptance is not called a counter", () {
      // The last thing a guest reads before the thread ends.
      expect(guest(false, 'accepted'), 'Accepted');
      expect(guest(false, 'accepted').toLowerCase().contains('counter'), isFalse);
    });

    test('a real counter still reads as one', () {
      expect(guest(false, 'pending'), 'Host countered');
      expect(guest(false, 'countered'), 'Host countered');
    });

    test('declined and expired say which', () {
      expect(guest(false, 'declined'), 'Declined');
      expect(guest(false, 'expired'), 'Expired');
    });
  });

  group("the host's screen", () {
    test('a host can tell which words the platform wrote for them', () {
      // The whole point of `automatic`: the platform answers in the host's
      // name, and an unqualified label would be something they never did.
      expect(host(true, 'accepted', automatic: true), 'Accepted for you');
      expect(host(true, 'pending', automatic: true),
          'Answered for you, at your price');
    });

    test("...and the host's own counter carries what became of it", () {
      expect(host(true, 'accepted'), 'Your counter was accepted');
      expect(host(true, 'declined'), 'Your counter was declined');
      expect(host(true, 'pending'), 'You countered');
    });

    test("the guest's side is labelled from the host's seat", () {
      expect(host(false, 'pending'), 'Guest offered');
      expect(host(false, 'declined'), 'Declined');
      expect(host(false, 'accepted'), 'Accepted');
    });

    test('case does not decide the label', () {
      expect(host(false, 'ACCEPTED'), 'Accepted');
      expect(guest(true, 'Declined'), 'Your offer was declined');
    });
  });

  group('the host thread the app had been throwing away', () {
    test('messages are parsed, not just counted', () {
      final n = HostNegotiation.fromJson({
        'offerId': 141,
        'propertyId': 29303,
        'propertyName': 'QA Metro PG Gurugram',
        'originalPrice': 1200,
        'offerPrice': 850,
        'status': 'pending',
        'messages': [
          {'offerId': 1, 'from': 'them', 'price': 900, 'status': 'countered'},
          {
            'offerId': 2,
            'from': 'you',
            'price': 1050,
            'status': 'countered',
            'automatic': true,
            'message': 'Thank you for the offer …',
          },
          {'offerId': 3, 'from': 'them', 'price': 850, 'status': 'pending'},
        ],
      });
      expect(n.rounds, 3, reason: 'the count must not change meaning');
      expect(n.messages.length, 3,
          reason: 'the endpoint has always sent these and the model counted '
              'the array and threw it away');
      expect(n.messages[1].label, 'Answered for you, at your price');
      expect(n.messages[0].label, 'Guest offered');
      expect(n.messages[1].mine, isTrue);
    });

    test('an older payload without the flag reads as the host own words', () {
      // "Nothing" must read as "the host wrote this": labelling a host's own
      // counter "Answered for you" is worse than leaving an automatic one
      // unmarked.
      final n = HostNegotiation.fromJson({
        'offerId': 1,
        'propertyId': 1,
        'offerPrice': 100,
        'status': 'pending',
        'messages': [
          {'offerId': 2, 'from': 'you', 'price': 120, 'status': 'countered'},
        ],
      });
      expect(n.messages.single.label, 'You countered');
    });

    test('no messages at all is not a crash', () {
      final n = HostNegotiation.fromJson(
          {'offerId': 1, 'propertyId': 1, 'offerPrice': 100, 'status': 'pending'});
      expect(n.messages, isEmpty);
      expect(n.rounds, 0);
      expect(n.roundLabel, isNull);
    });
  });
}
