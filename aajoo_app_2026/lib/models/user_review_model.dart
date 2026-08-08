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
        data: Data.fromJson(json["data"]),
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
        review: List<Review>.from(json["review"].map((x) => Review.fromJson(x))),
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
    int hruRating;
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
        hruRating: json["hru_rating"],
        images: List<dynamic>.from(json["images"].map((x) => x)),
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
