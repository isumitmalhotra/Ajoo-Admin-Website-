// To parse this JSON data, do
//
//     final transactionResponse = transactionResponseFromJson(jsonString);

import 'dart:convert';

TransactionResponse transactionResponseFromJson(String str) => TransactionResponse.fromJson(json.decode(str));

String transactionResponseToJson(TransactionResponse data) => json.encode(data.toJson());

class TransactionResponse {
    bool success;
    String message;
    List<Transaction> data;

    TransactionResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory TransactionResponse.fromJson(Map<String, dynamic> json) => TransactionResponse(
        success: json["success"],
        message: json["message"],
        data: List<Transaction>.from(json["data"].map((x) => Transaction.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Transaction {
    dynamic payId;
    String payInvoice;
    String payRazId;
    String payAmount;
    String payStatusText;
    DateTime payAddedAt;
    String userPaymentUserFullName;
    String paymentPropertyPropertyName;
    String paymentStatusBsTitle;
    dynamic paymentStatusBsCode;

    Transaction({
        required this.payId,
        required this.payInvoice,
        required this.payRazId,
        required this.payAmount,
        required this.payStatusText,
        required this.payAddedAt,
        required this.userPaymentUserFullName,
        required this.paymentPropertyPropertyName,
        required this.paymentStatusBsTitle,
        required this.paymentStatusBsCode,
    });

    factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        payId: json["pay_id"],
        payInvoice: json["pay_invoice"],
        payRazId: json["pay_raz_id"],
        payAmount: json["pay_amount"],
        payStatusText: json["pay_status_text"],
        payAddedAt: DateTime.parse(json["pay_addedAt"]),
        userPaymentUserFullName: json["userPayment.user_fullName"],
        paymentPropertyPropertyName: json["paymentProperty.property_name"],
        paymentStatusBsTitle: json["paymentStatus.bs_title"],
        paymentStatusBsCode: json["paymentStatus.bs_code"],
    );

    Map<String, dynamic> toJson() => {
        "pay_id": payId,
        "pay_invoice": payInvoice,
        "pay_raz_id": payRazId,
        "pay_amount": payAmount,
        "pay_status_text": payStatusText,
        "pay_addedAt": payAddedAt.toIso8601String(),
        "userPayment.user_fullName": userPaymentUserFullName,
        "paymentProperty.property_name": paymentPropertyPropertyName,
        "paymentStatus.bs_title": paymentStatusBsTitle,
        "paymentStatus.bs_code": paymentStatusBsCode,
    };
}
