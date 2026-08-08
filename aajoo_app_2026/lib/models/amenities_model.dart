// To parse this JSON data, do
//
//     final amenitiesResponse = amenitiesResponseFromJson(jsonString);

import 'dart:convert';

AmenitiesResponse amenitiesResponseFromJson(String str) => AmenitiesResponse.fromJson(json.decode(str));

String amenitiesResponseToJson(AmenitiesResponse data) => json.encode(data.toJson());

class AmenitiesResponse {
    bool success;
    String message;
    List<Amenity> data;

    AmenitiesResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory AmenitiesResponse.fromJson(Map<String, dynamic> json) => AmenitiesResponse(
        success: json["success"],
        message: json["message"],
        data: List<Amenity>.from(json["data"].map((x) => Amenity.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Amenity {
    int amnId;
    String amnTitle;

    Amenity({
        required this.amnId,
        required this.amnTitle,
    });

    factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
        amnId: json["amn_id"],
        amnTitle: json["amn_title"],
    );

    Map<String, dynamic> toJson() => {
        "amn_id": amnId,
        "amn_title": amnTitle,
    };
}
