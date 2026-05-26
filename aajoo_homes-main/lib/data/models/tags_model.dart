// To parse this JSON data, do
//
//     final tagsResponse = tagsResponseFromJson(jsonString);

import 'dart:convert';

TagsResponse tagsResponseFromJson(String str) => TagsResponse.fromJson(json.decode(str));

String tagsResponseToJson(TagsResponse data) => json.encode(data.toJson());

class TagsResponse {
    bool success;
    String message;
    Data data;

    TagsResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory TagsResponse.fromJson(Map<String, dynamic> json) => TagsResponse(
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
    List<Tag> tags;

    Data({
        required this.tags,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        tags: List<Tag>.from(json["tags"].map((x) => Tag.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "tags": List<dynamic>.from(tags.map((x) => x.toJson())),
    };
}

class Tag {
    int tagId;
    String tagName;

    Tag({
        required this.tagId,
        required this.tagName,
    });

    factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        tagId: json["tag_id"],
        tagName: json["tag_name"],
    );

    Map<String, dynamic> toJson() => {
        "tag_id": tagId,
        "tag_name": tagName,
    };
}
