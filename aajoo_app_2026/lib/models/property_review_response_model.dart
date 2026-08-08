class ReviewResponse {
  final bool? success;
  final String? message;
  final ReviewData? data;

  ReviewResponse({
    this.success,
    this.message,
    this.data,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? ReviewData.fromJson(json['data']) : null,
    );
  }
}

class ReviewData {
  final List<Review>? reviews;
  final String? averageRating;
  final Map<String, int>? allRatings;
  final List<MyReview>? myReview;

  ReviewData({
    this.reviews,
    this.averageRating,
    this.allRatings,
    this.myReview,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      reviews: json['reviews'] != null
          ? List<Review>.from(
              json['reviews'].map((review) => Review.fromJson(review)))
          : null,
      averageRating: json['averageRating'],
      allRatings: json['allRatings'] != null ? Map<String, int>.from(json['allRatings']) : null,
      myReview: json['myReview'] != null
          ? List<MyReview>.from(
              json['myReview'].map((review) => MyReview.fromJson(review)))
          : null,
    );
  }
}

class Review {
  final int? brId;
  final int? brPropId;
  final int? brHostId;
  final int? brUserId;
  final String? brRating;
  final String? brDesc;
  final DateTime? brAddedAt;
  final String? userFullName;
  final int? dislike;
  final int? like;

  Review({
    this.brId,
    this.brPropId,
    this.brHostId,
    this.brUserId,
    this.brRating,
    this.brDesc,
    this.brAddedAt,
    this.userFullName,
    this.dislike,
    this.like,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      brId: json['br_id'],
      brPropId: json['br_propId'],
      brHostId: json['br_hostId'],
      brUserId: json['br_userId'],
      brRating: json['br_rating'],
      brDesc: json['br_desc'],
      brAddedAt: json['br_addedAt'] != null ? DateTime.parse(json['br_addedAt']) : null,
      userFullName: json['userReview.user_fullName'],
      dislike: json['dislike'],
      like: json['like'],
    );
  }
}

class MyReview {
  final int? brId;
  final int? brPropId;
  final int? brHostId;
  final int? brUserId;
  final String? brRating;
  final String? brTitle;
  final String? brDesc;
  final int? brIsActive;
  final int? brIsDelete;
  final DateTime? brAddedAt;
  final DateTime? brUpdatedAt;
  final String? userFullName;

  MyReview({
    this.brId,
    this.brPropId,
    this.brHostId,
    this.brUserId,
    this.brRating,
    this.brTitle,
    this.brDesc,
    this.brIsActive,
    this.brIsDelete,
    this.brAddedAt,
    this.brUpdatedAt,
    this.userFullName,
  });

  factory MyReview.fromJson(Map<String, dynamic> json) {
    return MyReview(
      brId: json['br_id'],
      brPropId: json['br_propId'],
      brHostId: json['br_hostId'],
      brUserId: json['br_userId'],
      brRating: json['br_rating'],
      brTitle: json['br_title'],
      brDesc: json['br_desc'],
      brIsActive: json['br_isActive'],
      brIsDelete: json['br_isDelete'],
      brAddedAt: json['br_addedAt'] != null ? DateTime.parse(json['br_addedAt']) : null,
      brUpdatedAt: json['br_updatedAt'] != null ? DateTime.parse(json['br_updatedAt']) : null,
      userFullName: json['userReview.user_fullName'],
    );
  }
}
