// "You have none" and "the request failed" have to look different.
//
// Every response on this API is built by one helper:
//
//   const response = (req, res, status, success, message, data = []) => ...
//
// so a handler that returns early without a payload sends `data: []` — an
// empty ARRAY — while the same endpoint's populated answer sends an OBJECT.
// Both are HTTP 200 with success:true. That is the platform's convention and
// it is not going to change.
//
// Two models call `Data.fromJson(json["data"])` on it with no type check, so
// the empty case throws `type 'List<dynamic>' is not a subtype of type
// 'Map<String, dynamic>'` and the screen shows a failure instead of an empty
// state. Neither is an edge case:
//
//   * a host with nothing in progress  (POST /booking/ongoing-host)
//   * a guest no host has reviewed yet (GET /review/host/user-review-list)
//
// The second is EVERY guest on the platform today — nothing has been reviewed.
// The backend comment on that handler says the 200-with-empty exists so "the
// client can no longer tell 'you have none' from 'the request failed'"; the
// client could not, because the shape it sends for none is not the shape the
// app parses.
//
// Also here: hru_rating is a DOUBLE column and the write schema is
// `yup.number().min(1).max(5)` with no .integer(), so 4.5 is a legal rating —
// and it was being read into an `int`.
//
//   flutter test test/an_empty_list_is_not_a_failure_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/host_ongoing_response.dart';
import 'package:rent_home/models/user_review_model.dart' as ur;

/// What common.response sends when a handler returns early. Verbatim shape.
const noRecord = '{"success":true,"message":"no record found","data":[]}';

const hostHasBookings = '''
{
  "success": true,
  "message": "success",
  "data": {
    "totalcount": 1,
    "records": 1,
    "bookings": [
      {
        "book_pri_id": 41,
        "book_id": "B2026091200041",
        "book_prop_id": 29302,
        "book_user_id": 101,
        "book_host_id": 194,
        "book_status": 2,
        "bookDetails.bt_book_from": "12-09-2026",
        "bookDetails.bt_book_to": "13-09-2026",
        "userDetails.user_pnumber": "9882498033",
        "userDetails.user_fullName": "Aajoo Renter",
        "bookingStatus.bs_title": "Confirmed",
        "attachments": []
      }
    ]
  }
}
''';

const guestHasReviews = '''
{
  "success": true,
  "message": "success",
  "data": {
    "review": [
      {
        "hru_id": 3,
        "hru_bookingId": "B2026091200041",
        "hru_title": "Easy guest",
        "hru_description": "Left the place tidy and messaged before arriving.",
        "hru_rating": 4.5,
        "images": []
      }
    ]
  }
}
''';

Map<String, dynamic> body(String s) => json.decode(s) as Map<String, dynamic>;

void main() {
  group("a host with nothing in progress", () {
    test('reads as no bookings, not as a failure', () {
      final r = HostOnGoingBookingResponse.fromJson(body(noRecord));
      expect(r.success, isTrue);
      expect(r.data.bookings, isEmpty);
      expect(r.data.totalcount, 0);
      expect(r.data.records, 0);
    });

    test('and a host who has one still gets it', () {
      final r = HostOnGoingBookingResponse.fromJson(body(hostHasBookings));
      expect(r.data.bookings, hasLength(1));
      expect(r.data.totalcount, 1);
      final b = r.data.bookings.first;
      expect(b.bookId, 'B2026091200041');
      expect(b.userDetailsUserFullName, 'Aajoo Renter');
      expect(b.bookingStatusBsTitle, 'Confirmed');
    });
  });

  group('a guest no host has reviewed', () {
    test('reads as no reviews, not as a failure', () {
      // Every guest on the platform, today.
      final r = ur.UserReviewResponse.fromJson(body(noRecord));
      expect(r.success, isTrue);
      expect(r.data.review, isEmpty);
    });

    test('and a reviewed guest still gets their reviews', () {
      final r = ur.UserReviewResponse.fromJson(body(guestHasReviews));
      expect(r.data.review, hasLength(1));
      expect(r.data.review.first.hruTitle, 'Easy guest');
    });

    test('half a star is a legal rating', () {
      // hru_rating is DOUBLE(10,2) and the write schema is
      // yup.number().min(1).max(5) — no .integer() — so 4.5 goes in and comes
      // back out. Read into an `int` it threw.
      final r = ur.UserReviewResponse.fromJson(body(guestHasReviews));
      expect(r.data.review.first.hruRating, 4.5);
    });

    test('a whole star still prints without a decimal point', () {
      // The home screen renders this with .toString(), so `num` matters:
      // 4 stays "4" and does not become "4.0".
      final whole = guestHasReviews.replaceAll('"hru_rating": 4.5', '"hru_rating": 4');
      final r = ur.UserReviewResponse.fromJson(body(whole));
      expect(r.data.review.first.hruRating.toString(), '4');
    });
  });
}
