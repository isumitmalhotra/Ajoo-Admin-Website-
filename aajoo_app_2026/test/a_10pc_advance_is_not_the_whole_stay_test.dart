import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/booking_status.dart';
import 'package:rent_home/utils/sheet_insets.dart';

/// "I paid only 10% and it says you paid all."
///
/// Reported by the tester, 2026-09-23, with the Bookings list correctly
/// showing a balance still owing on the same stay.
///
/// The server sets `book_is_paid` on the FIRST verified rupee — including the
/// 10% that holds an advance booking — so the flag means "money arrived", not
/// "the stay is settled". Every screen that read it as the latter said paid.
///
/// `paymentBadge` already knew better: it has a "Deposit paid · ₹X due"
/// branch. It could not reach it because `payMode`, `total` and `amountPaid`
/// were OPTIONAL and defaulted to '', 0 and 0 — so a caller that omitted them
/// got a confident "Paid". The host's home screen omitted all three, and told
/// hosts they had been paid in full for stays that had sent them a tenth.
/// Those three are required now, so the compiler catches the next one.
void main() {
  group('a part-paid stay never reads as settled', () {
    test('10% of a stay is a deposit, not payment in full', () {
      final b = paymentBadge(
        isPaid: true,          // true after the very first rupee
        isCod: false,
        payMode: 'deposit',
        total: 1680,
        amountPaid: 168,
      );
      expect(b.label, isNot('Paid'));
      expect(b.label, contains('Deposit'));
      expect(b.label, contains('1,512'), reason: 'the guest owes 1680 - 168');
    });

    test('once the balance is settled it is simply paid', () {
      final b = paymentBadge(
        isPaid: true, isCod: false, payMode: 'full',
        total: 1680, amountPaid: 1680,
      );
      expect(b.label, 'Paid');
    });

    test('a rounding rupee is not a debt', () {
      final b = paymentBadge(
        isPaid: true, isCod: false, payMode: 'deposit',
        total: 1680, amountPaid: 1679.5,
      );
      expect(b.label, 'Paid');
    });

    test('pay-at-property is still its own thing', () {
      final b = paymentBadge(
        isPaid: false, isCod: true, payMode: '', total: 1680, amountPaid: 0,
      );
      expect(b.label, 'Pay at property');
    });

    test('a refund outranks the paid state', () {
      final b = paymentBadge(
        isPaid: true, isCod: false, payMode: 'full',
        total: 1680, amountPaid: 1680,
        refundAmount: 1680, refundStatus: 'COMPLETED',
      );
      expect(b.label, contains('Refunded'));
    });
  });

  group('a sheet button is not hidden by the navigation bar', () {
    /// viewInsets is the KEYBOARD; viewPadding is the NAVIGATION BAR. Handling
    /// only the first is why "Save guest" and "Apply" were unreachable with
    /// the keyboard closed.
    Widget probe(MediaQueryData mq, void Function(double) capture) =>
        MediaQuery(
          data: mq,
          child: Builder(builder: (ctx) {
            capture(sheetBottomInset(ctx));
            return const SizedBox();
          }),
        );

    testWidgets('keyboard closed: the navigation bar still counts',
        (tester) async {
      double? got;
      await tester.pumpWidget(probe(
        const MediaQueryData(
          viewInsets: EdgeInsets.zero,
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        (v) => got = v,
      ));
      expect(got, 48,
          reason: 'this is the case that hid the button — viewInsets is 0 here');
    });

    testWidgets('keyboard open: it covers the navigation bar, so do not add both',
        (tester) async {
      double? got;
      await tester.pumpWidget(probe(
        const MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: 320),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        (v) => got = v,
      ));
      expect(got, 320, reason: '368 would leave a gap above the keyboard');
    });

    testWidgets('a phone with neither gets no padding', (tester) async {
      double? got;
      await tester.pumpWidget(probe(const MediaQueryData(), (v) => got = v));
      expect(got, 0);
    });
  });
}
