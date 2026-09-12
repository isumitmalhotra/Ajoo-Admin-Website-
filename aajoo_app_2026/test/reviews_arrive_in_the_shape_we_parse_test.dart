// The reviews payload, in both the shapes it actually has.
//
// Checked after three models were found assigning raw json[...] into typed
// fields (see an_approximate_listing_still_parses_test). This one has the same
// SHAPE -- br_rating and averageRating are declared String? and assigned raw --
// but it is not the same defect, because of what is on the other end:
//
//   br_rating   DECIMAL(10,2)   -> the driver returns a STRING
//   averageRating               -> (total / n).toFixed(2), a JS string
//   like/dislike                -> JSON.parse(...).length, a JS number
//   allRatings                  -> { "<rating>": <count> }, JSON keys are text
//
// So every one of them lands in a field of the right type. The reason to pin it
// is that none of that is visible from the app: change br_rating to FLOAT, or
// wrap averageRating in Number(), and this model starts throwing on a screen
// nobody would think to re-test.
//
// The empty case is not hypothetical -- it is the only shape on the platform
// today. Every listing answers `{reviews: null, myReview: null}` with the
// message "No record found", because nothing has been reviewed yet, and that
// is exactly the response a guest opening a past stay gets.
//
//   flutter test test/reviews_arrive_in_the_shape_we_parse_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/property_review_response_model.dart';

/// Verbatim from GET-equivalent POST /properties/reviews/list on 2026-09-12,
/// for every property id on the platform.
const nothingYet =
    '{"success":true,"message":"No record found","data":{"reviews":null,"myReview":null}}';

/// The shape property.controller builds when there ARE reviews: the row
/// spread, plus the two computed counts, plus the average and the histogram.
/// Types are the column types, not a guess -- tbl_reviews.js and
/// calculateRatings().
const withReviews = '''
{
  "success": true,
  "message": "Success",
  "data": {
    "reviews": [
      {
        "br_id": 12,
        "br_propId": 29302,
        "br_hostId": 194,
        "br_userId": 101,
        "br_rating": "4.50",
        "br_title": "Lovely stay",
        "br_desc": "Quiet, clean, and the host left directions that actually worked.",
        "br_addedAt": "2026-09-11T09:14:22.000Z",
        "br_isActive": 1,
        "br_isDelete": 0,
        "userReview.user_fullName": "Aajoo Renter",
        "dislike": 0,
        "like": 3
      }
    ],
    "averageRating": "4.50",
    "allRatings": {"4.5": 1},
    "myReview": [
      {
        "br_id": 12,
        "br_propId": 29302,
        "br_hostId": 194,
        "br_userId": 101,
        "br_rating": "4.50",
        "br_title": "Lovely stay",
        "br_desc": "Quiet, clean, and the host left directions that actually worked.",
        "br_isActive": 1,
        "br_isDelete": 0,
        "userReview.user_fullName": "Aajoo Renter"
      }
    ]
  }
}
''';

Map<String, dynamic> body(String s) => json.decode(s) as Map<String, dynamic>;

void main() {
  group('nothing reviewed yet', () {
    test('the only shape on the platform today parses', () {
      final r = ReviewResponse.fromJson(body(nothingYet));
      expect(r.success, isTrue);
      expect(r.data, isNotNull);
      expect(r.data!.reviews, isNull,
          reason: 'a stay with no reviews must read as no reviews, not as a '
              'failure to load them');
      expect(r.data!.myReview, isNull);
      expect(r.data!.averageRating, isNull);
      expect(r.data!.allRatings, isNull);
    });

    test('a missing data block is not a crash', () {
      final r = ReviewResponse.fromJson(
          body('{"success":false,"message":"Something went wrong"}'));
      expect(r.data, isNull);
    });
  });

  group('a reviewed stay', () {
    test('parses the populated shape', () {
      final r = ReviewResponse.fromJson(body(withReviews));
      final d = r.data!;
      expect(d.reviews, hasLength(1));
      expect(d.myReview, hasLength(1));
      expect(d.reviews!.first.brId, 12);
      expect(d.reviews!.first.userFullName, 'Aajoo Renter');
      expect(d.reviews!.first.like, 3);
      expect(d.reviews!.first.brAddedAt, isNotNull);
    });

    test('the rating is TEXT on the wire, and stays text', () {
      // br_rating is DECIMAL(10,2), which the MySQL driver hands back as a
      // string, and averageRating is toFixed(2). If either ever becomes a
      // number this throws -- which is the point of the test.
      final d = ReviewResponse.fromJson(body(withReviews)).data!;
      expect(d.reviews!.first.brRating, '4.50');
      expect(d.averageRating, '4.50');
      expect(double.tryParse(d.averageRating!), 4.5,
          reason: 'whatever the wire type, the value has to read as a number');
    });

    test('the histogram is keyed by rating and counted in whole reviews', () {
      final d = ReviewResponse.fromJson(body(withReviews)).data!;
      expect(d.allRatings, {'4.5': 1});
    });
  });
}
