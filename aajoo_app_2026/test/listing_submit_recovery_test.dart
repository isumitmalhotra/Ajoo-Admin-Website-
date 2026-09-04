import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/listing_service.dart';

/// Tester #17 — "Submit for Review keeps loading even after property is
/// submitted". The server had done the work; the answer never arrived, and the
/// app sat on a spinner until a three-minute timeout meant for photo uploads.
///
/// The fix reads the listing back when the TRANSPORT fails, and only then. The
/// two rules below are what decide that, so they are what is worth pinning.
void main() {
  final opts = RequestOptions(path: '/listing/submit');

  group('isTransportFailure — recover only when the server never answered', () {
    test('timeouts and connection errors are transport failures', () {
      for (final t in [
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          ListingService.isTransportFailure(
              DioException(requestOptions: opts, type: t)),
          isTrue,
          reason: '$t',
        );
      }
    });

    test('an HTTP error response is an ANSWER, not a transport failure', () {
      // "Accept all the declarations" is the server talking. Reading the
      // listing back and calling it a success would hide a real refusal.
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: opts,
          statusCode: 400,
          data: {'message': 'Please accept all declarations before submitting'},
        ),
      );
      expect(ListingService.isTransportFailure(e), isFalse);
    });

    test('a timeout that still carried a response is not recovered', () {
      // Defensive: if a response exists at all, the server answered.
      final e = DioException(
        requestOptions: opts,
        type: DioExceptionType.receiveTimeout,
        response: Response(requestOptions: opts, statusCode: 504),
      );
      expect(ListingService.isTransportFailure(e), isFalse);
    });

    test('cancellation is not a transport failure', () {
      expect(
        ListingService.isTransportFailure(
            DioException(requestOptions: opts, type: DioExceptionType.cancel)),
        isFalse,
      );
    });
  });

  group('looksSubmitted — what counts as "it landed"', () {
    test('every state the server writes after accepting a submission', () {
      expect(ListingService.looksSubmitted('submitted'), isTrue);
      expect(ListingService.looksSubmitted('approved'), isTrue);
      // An admin can approve between the submit and the read-back.
      expect(ListingService.looksSubmitted('verified'), isTrue);
      expect(ListingService.looksSubmitted('held_for_verification'), isTrue);
    });

    test('case and padding do not change the answer', () {
      expect(ListingService.looksSubmitted('  SUBMITTED '), isTrue);
    });

    test('a listing that never left draft is NOT a success', () {
      expect(ListingService.looksSubmitted('draft'), isFalse);
      expect(ListingService.looksSubmitted('changes_requested'), isFalse);
      expect(ListingService.looksSubmitted('rejected'), isFalse);
      expect(ListingService.looksSubmitted('suspended'), isFalse);
    });

    test('unknown or missing reads false — cannot tell is not success', () {
      expect(ListingService.looksSubmitted(null), isFalse);
      expect(ListingService.looksSubmitted(''), isFalse);
      expect(ListingService.looksSubmitted('something_new'), isFalse);
    });
  });
}
