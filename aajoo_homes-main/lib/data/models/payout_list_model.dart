// To parse this JSON data, do
//
//     final payoutListResponse = payoutListResponseFromJson(jsonString);

import 'dart:convert';

PayoutListResponse payoutListResponseFromJson(String str) => PayoutListResponse.fromJson(json.decode(str));

String payoutListResponseToJson(PayoutListResponse data) => json.encode(data.toJson());

class PayoutListResponse {
    bool success;
    String message;
    Data data;

    PayoutListResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory PayoutListResponse.fromJson(Map<String, dynamic> json) => PayoutListResponse(
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
    int hostTotalEarning;
    int earningLeft;
    List<PayoutRequest> payoutRequests;

    Data({
        required this.hostTotalEarning,
        required this.earningLeft,
        required this.payoutRequests,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        hostTotalEarning: json["hostTotalEarning"],
        earningLeft: json["earningLeft"],
        payoutRequests: List<PayoutRequest>.from(json["payoutRequests"].map((x) => PayoutRequest.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "hostTotalEarning": hostTotalEarning,
        "earningLeft": earningLeft,
        "payoutRequests": List<dynamic>.from(payoutRequests.map((x) => x.toJson())),
    };
}

class PayoutRequest {
    int payReqId;
    int payReqAmount;
    int payReqIsActive;
    DateTime createdAt;
    String payoutStatusBsTitle;
    dynamic payoutStatusBsCode;

    PayoutRequest({
        required this.payReqId,
        required this.payReqAmount,
        required this.payReqIsActive,
        required this.createdAt,
        required this.payoutStatusBsTitle,
        required this.payoutStatusBsCode,
    });

    factory PayoutRequest.fromJson(Map<String, dynamic> json) => PayoutRequest(
        payReqId: json["pay_req_id"],
        payReqAmount: json["pay_req_amount"],
        payReqIsActive: json["pay_req_isActive"],
        createdAt: DateTime.parse(json["createdAt"]),
        payoutStatusBsTitle: json["payoutStatus.bs_title"],
        payoutStatusBsCode: json["payoutStatus.bs_code"],
    );

    Map<String, dynamic> toJson() => {
        "pay_req_id": payReqId,
        "pay_req_amount": payReqAmount,
        "pay_req_isActive": payReqIsActive,
        "createdAt": createdAt.toIso8601String(),
        "payoutStatus.bs_title": payoutStatusBsTitle,
        "payoutStatus.bs_code": payoutStatusBsCode,
    };
}
