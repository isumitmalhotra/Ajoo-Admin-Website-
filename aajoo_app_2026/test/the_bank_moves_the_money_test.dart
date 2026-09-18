// Manual host payouts — client decision, 2026-09-18. The app's share: a
// payout row says what the bank did (method, UTR) and what the run withheld;
// a freshly saved account reads "awaiting verification", a thing that will
// happen, rather than a failure.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/host_account_details_model.dart';
import 'package:rent_home/models/payout_list_model.dart';

void main() {
  group('a payout row, in the host\'s words', () {
    test('a paid row carries the method and UTR the bank gave', () {
      final r = PayoutRequest.fromPayoutRow({
        'po_id': 41, 'po_amount': '13400.00', 'po_status': 'COMPLETED',
        'po_completed_at': '2026-09-18T09:30:00.000Z', 'po_reference_id': 'B182882',
        'po_utr': 'N20260918ABC', 'po_mode': 'NEFT', 'po_note': 'Paid in run PR-0001.',
      });
      expect(r.statusLabel, 'Paid');
      expect(r.statusDetail, 'by NEFT · UTR N20260918ABC');
      expect(r.withheldNote, isNull);
    });

    test('a row whose batch had dues withheld says so, without the run bookkeeping', () {
      final r = PayoutRequest.fromPayoutRow({
        'po_id': 42, 'po_amount': '8400.00', 'po_status': 'COMPLETED', 'po_utr': 'X1', 'po_mode': 'IMPS',
        'po_note': 'Paid in run PR-0001; ₹1200 of this host\'s batch withheld for pay-at-property settlement(s) 7.',
      });
      expect(r.withheldNote, startsWith('₹1200 of this host'));
      expect(r.withheldNote, isNot(contains('Paid in run')));
    });

    test('queued, processing and failed rows explain themselves', () {
      expect(PayoutRequest.fromPayoutRow({'po_id': 1, 'po_amount': 1, 'po_status': 'QUEUED'}).statusDetail, 'Released on the next payout run.');
      expect(PayoutRequest.fromPayoutRow({'po_id': 2, 'po_amount': 1, 'po_status': 'PROCESSING'}).statusLabel, 'Being paid');
      final failed = PayoutRequest.fromPayoutRow({'po_id': 3, 'po_amount': 1, 'po_status': 'FAILED', 'po_failure_reason': 'Account closed'});
      expect(failed.statusLabel, 'Not paid');
      expect(failed.statusDetail, 'Account closed');
    });
  });

  group('the account badge', () {
    test('awaiting the ₹1 test is amber and says what will happen', () {
      final a = HostAccountDetails.fromJson({
        'accountNumber': 'XXXX9012', 'ifsc': 'HDFC0001234', 'accountHolderName': 'Sam',
        'isVerified': false, 'verifyStatus': 'awaiting_manual',
      });
      expect(a.verifyLabel, 'Awaiting verification');
      expect(a.isAwaiting, isTrue);
      expect(a.verifyExplanation, contains('₹1'));
    });

    test('a rejected account reads "needs attention" with the reason finance gave', () {
      final a = HostAccountDetails.fromJson({
        'accountNumber': 'XXXX9012', 'isVerified': false, 'verifyStatus': 'failed',
        'verifyNote': 'Name on the account does not match (finance, admin #7)',
      });
      expect(a.verifyLabel, 'Needs attention');
      expect(a.isAwaiting, isFalse);
      expect(a.verifyExplanation, contains('Name on the account'));
    });
  });
}
