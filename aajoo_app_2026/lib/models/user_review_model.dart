// To parse this JSON data, do
//
//     final userReviewResponse = userReviewResponseFromJson(jsonString);

import 'dart:convert';

UserReviewResponse userReviewResponseFromJson(String str) => UserReviewResponse.fromJson(json.decode(str));

String userReviewResponseToJson(UserReviewResponse data) => json.encode(data.toJson());

class UserReviewResponse {
    bool success;
    String message;
    Data data;

    UserReviewResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory UserReviewResponse.fromJson(Map<String, dynamic> json) => UserReviewResponse(
        success: json["success"],
        message: json["message"],
        // `data` is an empty ARRAY when there is nothing to send.
        //
        // Every response on this API comes from one helper whose signature
        // ends `data = []`, so a handler that returns early without a payload
        // sends `data: []` while its populated answer sends an object. Both
        // are 200 with success:true. Calling Data.fromJson on the array threw
        // `List<dynamic> is not a subtype of Map<String, dynamic>`, so having
        // none looked exactly like a failed request -- which is the one
        // distinction the backend added that branch to make.
        data: Data.fromJson(json["data"] is Map<String, dynamic>
            ? json["data"] as Map<String, dynamic>
            : const <String, dynamic>{}),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
    };
}

class Data {
    List<Review> review;

    Data({
        required this.review,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        review: json["review"] is List
            ? List<Review>.from(
                (json["review"] as List).map((x) => Review.fromJson(x)))
            : <Review>[],
    );

    Map<String, dynamic> toJson() => {
        "review": List<dynamic>.from(review.map((x) => x.toJson())),
    };
}

class Review {
    int hruId;
    String hruBookingId;
    String hruTitle;
    String hruDescription;
    /// `num`, not `int`.
    ///
    /// hru_rating is a DOUBLE(10,2) column and the write schema is
    /// `yup.number().min(1).max(5)` with no `.integer()`, so 4.5 is a legal
    /// rating that the database is shaped to hold -- and `4.5` decodes to a
    /// Dart double, which is not an int. `num` takes both wire forms, and
    /// keeps `4` printing as "4" rather than "4.0" where the home screen
    /// renders it with toString().
    num hruRating;
    List<dynamic> images;

    Review({
        required this.hruId,
        required this.hruBookingId,
        required this.hruTitle,
        required this.hruDescription,
        required this.hruRating,
        required this.images,
    });

    factory Review.fromJson(Map<String, dynamic> json) => Review(
        hruId: json["hru_id"],
        hruBookingId: json["hru_bookingId"],
        hruTitle: json["hru_title"],
        hruDescription: json["hru_description"],
        hruRating: (json["hru_rating"] as num?) ??
            num.tryParse('${json["hru_rating"] ?? ''}') ??
            0,
        // Attached only when the review has photographs.
        images: json["images"] is List
            ? List<dynamic>.from(json["images"] as List)
            : <dynamic>[],
    );

    Map<String, dynamic> toJson() => {
        "hru_id": hruId,
        "hru_bookingId": hruBookingId,
        "hru_title": hruTitle,
        "hru_description": hruDescription,
        "hru_rating": hruRating,
        "images": List<dynamic>.from(images.map((x) => x)),
    };
}
