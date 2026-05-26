// To parse this JSON data, do
//
//     final faqResponse = faqResponseFromJson(jsonString);

import 'dart:convert';

FaqResponse faqResponseFromJson(String str) => FaqResponse.fromJson(json.decode(str));

String faqResponseToJson(FaqResponse data) => json.encode(data.toJson());

class FaqResponse {
    bool success;
    String message;
    FaqData data;

    FaqResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory FaqResponse.fromJson(Map<String, dynamic> json) => FaqResponse(
        success: json["success"],
        message: json["message"],
        data: FaqData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
    };
}

class FaqData {
    List<FaqDatum> faqData;

    FaqData({
        required this.faqData,
    });

    factory FaqData.fromJson(Map<String, dynamic> json) => FaqData(
        faqData: List<FaqDatum>.from(json["faqData"].map((x) => FaqDatum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "faqData": List<dynamic>.from(faqData.map((x) => x.toJson())),
    };
}

class FaqDatum {
    String title;
    String description;

    FaqDatum({
        required this.title,
        required this.description,
    });

    factory FaqDatum.fromJson(Map<String, dynamic> json) => FaqDatum(
        title: json["title"],
        description: json["description"],
    );

    Map<String, dynamic> toJson() => {
        "title": title,
        "description": description,
    };
}
