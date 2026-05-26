// To parse this JSON data, do
//
//     final docTypeResponse = docTypeResponseFromJson(jsonString);

import 'dart:convert';

DocTypeResponse docTypeResponseFromJson(String str) => DocTypeResponse.fromJson(json.decode(str));

String docTypeResponseToJson(DocTypeResponse data) => json.encode(data.toJson());

class DocTypeResponse {
    bool success;
    String message;
    List<DocTypeData> data;

    DocTypeResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory DocTypeResponse.fromJson(Map<String, dynamic> json) => DocTypeResponse(
        success: json["success"],
        message: json["message"],
        data: List<DocTypeData>.from(json["data"].map((x) => DocTypeData.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class DocTypeData {
    int dId;
    String dTitle;

    DocTypeData({
        required this.dId,
        required this.dTitle,
    });

    factory DocTypeData.fromJson(Map<String, dynamic> json) => DocTypeData(
        dId: json["d_id"],
        dTitle: json["d_title"],
    );

    Map<String, dynamic> toJson() => {
        "d_id": dId,
        "d_title": dTitle,
    };
}
