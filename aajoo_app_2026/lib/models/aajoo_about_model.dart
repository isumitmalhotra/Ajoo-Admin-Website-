// To parse this JSON data, do
//
//     final aajooModel = aajooModelFromJson(jsonString);

import 'dart:convert';

AajooModel aajooModelFromJson(String str) => AajooModel.fromJson(json.decode(str));

String aajooModelToJson(AajooModel data) => json.encode(data.toJson());

class AajooModel {
    bool success;
    String message;
    Data data;

    AajooModel({
        required this.success,
        required this.message,
        required this.data,
    });

    factory AajooModel.fromJson(Map<String, dynamic> json) => AajooModel(
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
    AboutData aboutData;

    Data({
        required this.aboutData,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        aboutData: AboutData.fromJson(json["aboutData"]),
    );

    Map<String, dynamic> toJson() => {
        "aboutData": aboutData.toJson(),
    };
}

class AboutData {
    String aboutUs;
    String ourMission;
    String ourVision;
    String joinUs;
    String quote;
    String forHosts;
    String forUsers;
    WhatMakesUsDifferent whatMakesUsDifferent;

    AboutData({
        required this.aboutUs,
        required this.ourMission,
        required this.ourVision,
        required this.joinUs,
        required this.quote,
        required this.forHosts,
        required this.forUsers,
        required this.whatMakesUsDifferent,
    });

    factory AboutData.fromJson(Map<String, dynamic> json) => AboutData(
        aboutUs: json["About Us"],
        ourMission: json["Our Mission"],
        ourVision: json["Our Vision"],
        joinUs: json["Join Us"],
        quote: json["quote"],
        forHosts: json["For Hosts"],
        forUsers: json["For Users"],
        whatMakesUsDifferent: WhatMakesUsDifferent.fromJson(json["What Makes Us Different?"]),
    );

    Map<String, dynamic> toJson() => {
        "About Us": aboutUs,
        "Our Mission": ourMission,
        "Our Vision": ourVision,
        "Join Us": joinUs,
        "quote": quote,
        "For Hosts": forHosts,
        "For Users": forUsers,
        "What Makes Us Different?": whatMakesUsDifferent.toJson(),
    };
}

class WhatMakesUsDifferent {
    String walkingDistanceOptimization;
    String priceNegotiation;
    String luxuriousOptions;
    String safetyAndTrust;
    String feedbackDriven;

    WhatMakesUsDifferent({
        required this.walkingDistanceOptimization,
        required this.priceNegotiation,
        required this.luxuriousOptions,
        required this.safetyAndTrust,
        required this.feedbackDriven,
    });

    factory WhatMakesUsDifferent.fromJson(Map<String, dynamic> json) => WhatMakesUsDifferent(
        walkingDistanceOptimization: json["Walking Distance Optimization"],
        priceNegotiation: json["Price Negotiation"],
        luxuriousOptions: json["Luxurious Options"],
        safetyAndTrust: json["Safety and Trust"],
        feedbackDriven: json["Feedback-Driven"],
    );

    Map<String, dynamic> toJson() => {
        "Walking Distance Optimization": walkingDistanceOptimization,
        "Price Negotiation": priceNegotiation,
        "Luxurious Options": luxuriousOptions,
        "Safety and Trust": safetyAndTrust,
        "Feedback-Driven": feedbackDriven,
    };
}
