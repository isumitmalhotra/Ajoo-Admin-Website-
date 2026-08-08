// To parse this JSON data, do
//
//     final propertiesResponse = propertiesResponseFromJson(jsonString);

import 'dart:convert';

PropertiesResponse propertiesResponseFromJson(String str) =>
    PropertiesResponse.fromJson(json.decode(str));

String propertiesResponseToJson(PropertiesResponse data) =>
    json.encode(data.toJson());

class PropertiesResponse {
  bool success;
  String message;
  Data data;

  PropertiesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PropertiesResponse.fromJson(Map<String, dynamic> json) =>
      PropertiesResponse(
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
  List<Property> property;

  Data({
    required this.property,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        property: List<Property>.from(
            json["property"].map((x) => Property.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "property": List<dynamic>.from(property.map((x) => x.toJson())),
      };
}

class Property {
  int propertyId;
  String propertyName;
  String propertyAddress;
  String propertyDesc;
  String propertyPrice;
  String propertyCity;
  String propertyLongitude;
  String propertyLatitude;
  int propertyHostId;
  dynamic propertyZip;
  String? propertyContact;
  String? propertyEmail;
  double? distance;
  bool? propDetailsPropDetailIsPetFriendly;
  bool? propDetailsPropDetailIsSmoke;
  String? propDetailsPropDetailInTime;
  String? propDetailsPropDetailOutTime;
  String? propDetailsPropDetailExtra;
  String? coverImage;
  List<String> images;
  List<String> categoryTitles;
  List<String>? tags;
  List<String>? categories;
  List<String>? amenities;

  Property({
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
    required this.propertyDesc,
    required this.propertyPrice,
    required this.propertyCity,
    required this.propertyLongitude,
    required this.propertyLatitude,
    required this.propertyHostId,
    required this.propertyZip,
    this.propertyContact,
    this.distance,
    this.propDetailsPropDetailIsPetFriendly,
    this.propDetailsPropDetailIsSmoke,
    this.propDetailsPropDetailInTime,
    this.propDetailsPropDetailOutTime,
    this.propDetailsPropDetailExtra,
    this.coverImage,
    this.propertyEmail,
    required this.images,
    required this.categoryTitles,
    this.tags,
    this.categories,
    this.amenities,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        propertyId: json["property_id"],
        propertyName: json["property_name"],
        propertyAddress: json["property_address"],
        propertyDesc: json["property_desc"],
        propertyPrice: json["property_price"],
        propertyCity: json["property_city"],
        propertyLongitude: json["property_longitude"],
        propertyLatitude: json["property_latitude"],
        propertyHostId: json["property_host_id"],
        propertyZip: json["property_zip"],
        propertyContact: json["property_contact"]?.toString(),
        propertyEmail: json["property_email"]?.toString(),
        distance: (json["distance"] as num?)?.toDouble(),
        propDetailsPropDetailIsPetFriendly:
            json["propDetails.propDetail_isPetFriendly"] as bool?,
        propDetailsPropDetailIsSmoke:
            json["propDetails.propDetail_isSmoke"] as bool?,
        propDetailsPropDetailInTime:
            json["propDetails.propDetail_inTime"]?.toString(),
        propDetailsPropDetailOutTime:
            json["propDetails.propDetail_outTime"]?.toString(),
        propDetailsPropDetailExtra:
            json["propDetails.propDetail_extra"]?.toString(),
        coverImage: json["coverImage"]?.toString(),
        images: json["images"] == null
            ? <String>[]
            : List<String>.from(
                (json["images"] as List).map((x) => x.toString())),
        categoryTitles: json["category_titles"] == null
            ? <String>[]
            : List<String>.from(
                (json["category_titles"] as List).map((x) => x.toString())),
        tags: json["tags"] != null
            ? List<String>.from((json["tags"] as List).map((x) => x.toString()))
            : null,
        categories: json["categories"] != null
            ? List<String>.from(
                (json["categories"] as List).map((x) => x.toString()))
            : null,
        amenities: json["amenities"] != null
            ? List<String>.from(
                (json["amenities"] as List).map((x) => x.toString()))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "property_id": propertyId,
        "property_name": propertyName,
        "property_address": propertyAddress,
        "property_desc": propertyDesc,
        "property_price": propertyPrice,
        "property_city": propertyCity,
        "property_longitude": propertyLongitude,
        "property_latitude": propertyLatitude,
        "property_host_id": propertyHostId,
        "property_zip": propertyZip,
        "property_contact": propertyContact,
        "property_email": propertyEmail,
        "distance": distance,
        "propDetails.propDetail_isPetFriendly":
            propDetailsPropDetailIsPetFriendly,
        "propDetails.propDetail_isSmoke": propDetailsPropDetailIsSmoke,
        "propDetails.propDetail_inTime": propDetailsPropDetailInTime,
        "propDetails.propDetail_outTime": propDetailsPropDetailOutTime,
        "propDetails.propDetail_extra": propDetailsPropDetailExtra,
        "coverImage": coverImage,
        "images": List<dynamic>.from(images.map((x) => x)),
        "category_titles": List<dynamic>.from(categoryTitles.map((x) => x)),
        "tags": tags != null ? List<dynamic>.from(tags!.map((x) => x)) : null,
        "categories": categories != null
            ? List<dynamic>.from(categories!.map((x) => x))
            : null,
        "amenities": amenities != null
            ? List<dynamic>.from(amenities!.map((x) => x))
            : null,
      };
}
