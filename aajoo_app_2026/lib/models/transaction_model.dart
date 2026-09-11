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
    /// The PRE-TAX room subtotal. Host earnings are credited from it; it is
    /// not what the guest paid. See [chargedAmount].
    String payAmount;
    /// What the gateway took for this payment, when the server recorded it.
    String? payGatewayAmount;
    /// The booking's tax-inclusive total, tax, and pre-tax price — sent by the
    /// server since 2026-09-11, absent on rows from an older one.
    String? payTotalAmount;
    String? payTaxAmount;
    String? payBaseAmount;
    String? payBookId;
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
        this.payGatewayAmount,
        this.payTotalAmount,
        this.payTaxAmount,
        this.payBaseAmount,
        this.payBookId,
        required this.payStatusText,
        required this.payAddedAt,
        required this.userPaymentUserFullName,
        required this.paymentPropertyPropertyName,
        required this.paymentStatusBsTitle,
        required this.paymentStatusBsCode,
    });

    /// What the guest was CHARGED for this stay: the booking's tax-inclusive
    /// total, else what the gateway took, else the subtotal (a row from before
    /// either was recorded, where the two are one figure).
    ///
    /// The Invoices screen printed [payAmount] — ₹5,000 for Inv_205678 while
    /// the booking card beside it said ₹5,250 — and its own PDF of the
    /// invoice read "Total: ₹5,000" where the website's read ₹5,250. An
    /// invoice is the one thing a host forwards to a guest.
    num get chargedAmount =>
        _num(payTotalAmount) ?? _num(payGatewayAmount) ?? _num(payAmount) ?? 0;

    /// GST on the stay; 0 when the server did not say.
    num get taxAmount => _num(payTaxAmount) ?? 0;

    static num? _num(Object? v) {
      if (v == null) return null;
      if (v is num) return v;
      final n = num.tryParse(v.toString());
      return n == null || n == 0 ? null : n;
    }

    factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        payId: json["pay_id"],
        payInvoice: json["pay_invoice"]?.toString() ?? '',
        payRazId: json["pay_raz_id"]?.toString() ?? '',
        payAmount: json["pay_amount"]?.toString() ?? '0',
        payGatewayAmount: json["pay_gateway_amount"]?.toString(),
        payTotalAmount: json["pay_total_amount"]?.toString(),
        payTaxAmount: json["pay_tax_amount"]?.toString(),
        payBaseAmount: json["pay_base_amount"]?.toString(),
        payBookId: json["pay_bookId"]?.toString(),
        payStatusText: json["pay_status_text"]?.toString() ?? '',
        payAddedAt: DateTime.parse(json["pay_addedAt"]),
        userPaymentUserFullName: json["userPayment.user_fullName"]?.toString() ?? 'Guest',
        paymentPropertyPropertyName: json["paymentProperty.property_name"]?.toString() ?? '',
        paymentStatusBsTitle: json["paymentStatus.bs_title"]?.toString() ?? '',
        paymentStatusBsCode: json["paymentStatus.bs_code"],
    );

    Map<String, dynamic> toJson() => {
        "pay_id": payId,
        "pay_invoice": payInvoice,
        "pay_raz_id": payRazId,
        "pay_amount": payAmount,
        "pay_gateway_amount": payGatewayAmount,
        "pay_total_amount": payTotalAmount,
        "pay_tax_amount": payTaxAmount,
        "pay_base_amount": payBaseAmount,
        "pay_bookId": payBookId,
        "pay_status_text": payStatusText,
        "pay_addedAt": payAddedAt.toIso8601String(),
        "userPayment.user_fullName": userPaymentUserFullName,
        "paymentProperty.property_name": paymentPropertyPropertyName,
        "paymentStatus.bs_title": paymentStatusBsTitle,
        "paymentStatus.bs_code": paymentStatusBsCode,
    };
}
