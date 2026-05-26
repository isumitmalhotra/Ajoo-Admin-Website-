// To parse this JSON data, do
//
//     final categoryResponse = categoryResponseFromJson(jsonString);

import 'dart:convert';

CategoryResponse categoryResponseFromJson(String str) => CategoryResponse.fromJson(json.decode(str));

String categoryResponseToJson(CategoryResponse data) => json.encode(data.toJson());

class CategoryResponse {
    bool success;
    String message;
    Data data;

    CategoryResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory CategoryResponse.fromJson(Map<String, dynamic> json) => CategoryResponse(
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
    List<Category> categories;

    Data({
        required this.categories,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        categories: List<Category>.from(json["categories"].map((x) => Category.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
    };
}

class Category {
    int catId;
    String catTitle;

    Category({
        required this.catId,
        required this.catTitle,
    });

    factory Category.fromJson(Map<String, dynamic> json) => Category(
        catId: json["cat_id"],
        catTitle: json["cat_title"],
    );

    Map<String, dynamic> toJson() => {
        "cat_id": catId,
        "cat_title": catTitle,
    };
}
