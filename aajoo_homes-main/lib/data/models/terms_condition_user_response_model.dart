// To parse this JSON data, do
//
//     final termsAndCondionResponse = termsAndCondionResponseFromJson(jsonString);

import 'dart:convert';

TermsAndCondionResponse termsAndCondionResponseFromJson(String str) => TermsAndCondionResponse.fromJson(json.decode(str));

String termsAndCondionResponseToJson(TermsAndCondionResponse data) => json.encode(data.toJson());

class TermsAndCondionResponse {
    bool? success;
    String? message;
    TermsAndConditonData? data;

    TermsAndCondionResponse({
        this.success,
        this.message,
        this.data,
    });

    factory TermsAndCondionResponse.fromJson(Map<String, dynamic> json) => TermsAndCondionResponse(
        success: json["success"],
        message: json["message"],
        data: TermsAndConditonData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
    };
}

class TermsAndConditonData {
    Map<String, List<String>>? termsAndCondion;

    TermsAndConditonData({
        this.termsAndCondion,
    });

    factory TermsAndConditonData.fromJson(Map<String, dynamic> json) => TermsAndConditonData(
        termsAndCondion: Map.from(json["termsAndCondion"]).map((k, v) => MapEntry<String, List<String>>(k, List<String>.from(v.map((x) => x)))),
    );

    Map<String, dynamic> toJson() => {
        "termsAndCondion": termsAndCondion != null ? Map.from(termsAndCondion!).map((k, v) => MapEntry<String, dynamic>(k, List<dynamic>.from(v.map((x) => x)))) : null,
    };
}
