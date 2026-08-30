// To parse this JSON data, do
//
//     final searchResponse = searchResponseFromJson(jsonString);

import 'dart:convert';
import 'package:rent_home/models/property_offer.dart';

SearchResponse searchResponseFromJson(String str) =>
    SearchResponse.fromJson(json.decode(str));

String searchResponseToJson(SearchResponse data) => json.encode(data.toJson());

class SearchResponse {
  bool success;
  String message;
  List<SearchPropertyModel> data;

  SearchResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) => SearchResponse(
        success: json["success"],
        message: json["message"],
        data: List<SearchPropertyModel>.from(
            json["data"].map((x) => SearchPropertyModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

/// The server sends the average as a string ("4.50"), a number, or null.
/// Null stays null — see the note on [SearchPropertyModel.rating].
double? _asRating(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int _asCount(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? 0;
}

List<String>? _asStringList(dynamic v) {
  if (v is List) {
    final out = v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return out.isEmpty ? null : out;
  }
  return null;
}

class SearchPropertyModel {
  /// A discount running on this listing right now, priced by the server.
  /// Null when there is none — see [PropertyOffer].
  PropertyOffer? offer;

  dynamic propertyId;
  dynamic propertyHostId;
  String? propertyName;
  String? propertyAddress;
  String? propertyLongitude;
  String? propertyLatitude;
  String? propertyDesc;
  String? propertyPrice;
  String? propertyMiniPrice;
  String? propertyCity;
  dynamic propertyZip;
  dynamic propertyState;
  String? propertyContry;
  String? propertyContact;
  String? propertyEmail;
  bool isActive;
  int isDeleted;
  int isLuxury;
  DateTime createdAt;
  DateTime updatedAt;
  bool? propDetailsPropDetailIsPetFriendly;
  bool? propDetailsPropDetailIsSmoke;
  String? propDetailsPropDetailInTime;
  String? propDetailsPropDetailOutTime;
  String? propDetailsPropDetailExtra;
  String? coverImage;
  List<String>? images;
  dynamic categoryTitles;

  /// Guest rating out of 5, or null when nobody has reviewed the stay yet.
  ///
  /// /properties/list has always returned this (attachRatings runs over every
  /// row before the response is sent) — the model simply threw it away, so the
  /// app had no way to sort or filter by rating while the website could. Null
  /// is not zero: an unrated stay is unknown, not bad, and every comparison
  /// here keeps those two apart.
  double? rating;
  int reviewCount;

  /// Amenity titles, already filtered to the active ones by the server.
  List<String>? amenities;

  SearchPropertyModel({
    this.offer,
    this.propertyId,
    this.propertyHostId,
    this.propertyName,
    this.propertyAddress,
    this.propertyLongitude,
    this.propertyLatitude,
    this.propertyDesc,
    this.propertyPrice,
    this.propertyMiniPrice,
    this.propertyCity,
    this.propertyZip,
    this.propertyState,
    this.propertyContry,
    this.propertyContact,
    this.propertyEmail,
    required this.isActive,
    required this.isDeleted,
    required this.isLuxury,
    required this.createdAt,
    required this.updatedAt,
    this.propDetailsPropDetailIsPetFriendly,
    this.propDetailsPropDetailIsSmoke,
    this.propDetailsPropDetailInTime,
    this.propDetailsPropDetailOutTime,
    this.propDetailsPropDetailExtra,
    this.coverImage,
    this.images,
    this.categoryTitles,
    this.rating,
    this.reviewCount = 0,
    this.amenities,
  });

  factory SearchPropertyModel.fromJson(Map<String, dynamic> json) =>
      SearchPropertyModel(
        offer: PropertyOffer.fromJson(json['offer']),
        propertyId: json["property_id"],
        propertyHostId: json["property_host_id"],
        propertyName: json["property_name"],
        propertyAddress: json["property_address"],
        propertyLongitude: json["property_longitude"],
        propertyLatitude: json["property_latitude"],
        propertyDesc: json["property_desc"],
        propertyPrice: json["property_price"],
        propertyMiniPrice: json["property_mini_price"],
        propertyCity: json["property_city"],
        propertyZip: json["property_zip"],
        propertyState: json["property_state"],
        propertyContry: json["property_contry"],
        propertyContact: json["property_contact"],
        propertyEmail: json["property_email"],
        isActive: json["is_active"],
        isDeleted: json["is_deleted"],
        isLuxury: json["is_luxury"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        propDetailsPropDetailIsPetFriendly:
            json["propDetails.propDetail_isPetFriendly"],
        propDetailsPropDetailIsSmoke: json["propDetails.propDetail_isSmoke"],
        propDetailsPropDetailInTime: json["propDetails.propDetail_inTime"],
        propDetailsPropDetailOutTime: json["propDetails.propDetail_outTime"],
        propDetailsPropDetailExtra: json["propDetails.propDetail_extra"],
        coverImage: json["coverImage"],
        images: List<String>.from(json["images"].map((x) => x)),
        categoryTitles: json["category_titles"],
        rating: _asRating(json["rating"]),
        reviewCount: _asCount(json["review_count"] ?? json["reviewCount"]),
        amenities: _asStringList(json["amenities"]),
      );

  Map<String, dynamic> toJson() => {
        "property_id": propertyId,
        "property_host_id": propertyHostId,
        "property_name": propertyName,
        "property_address": propertyAddress,
        "property_longitude": propertyLongitude,
        "property_latitude": propertyLatitude,
        "property_desc": propertyDesc,
        "property_price": propertyPrice,
        "property_mini_price": propertyMiniPrice,
        "property_city": propertyCity,
        "property_zip": propertyZip,
        "property_state": propertyState,
        "property_contry": propertyContry,
        "property_contact": propertyContact,
        "property_email": propertyEmail,
        "is_active": isActive,
        "is_deleted": isDeleted,
        "is_luxury": isLuxury,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "propDetails.propDetail_isPetFriendly":
            propDetailsPropDetailIsPetFriendly,
        "propDetails.propDetail_isSmoke": propDetailsPropDetailIsSmoke,
        "propDetails.propDetail_inTime": propDetailsPropDetailInTime,
        "propDetails.propDetail_outTime": propDetailsPropDetailOutTime,
        "propDetails.propDetail_extra": propDetailsPropDetailExtra,
        "coverImage": coverImage,
        "images": List<dynamic>.from(images!.map((x) => x)),
        "category_titles": categoryTitles,
        "rating": rating,
        "review_count": reviewCount,
        "amenities": amenities,
      };
}
