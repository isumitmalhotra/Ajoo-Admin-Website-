// To parse this JSON data, do
//
//     final hostBookingHistoryResponse = hostBookingHistoryResponseFromJson(jsonString);

import 'dart:convert';

HostBookingHistoryResponse hostBookingHistoryResponseFromJson(String str) =>
    HostBookingHistoryResponse.fromJson(json.decode(str));

String hostBookingHistoryResponseToJson(HostBookingHistoryResponse data) =>
    json.encode(data.toJson());

class HostBookingHistoryResponse {
  bool success;
  String message;
  List<HostBookingHistory> data;

  HostBookingHistoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory HostBookingHistoryResponse.fromJson(Map<String, dynamic> json) =>
      HostBookingHistoryResponse(
        success: json["success"] == true,
        message: json["message"]?.toString() ?? "",
        data: (json["data"] is List)
            ? (json["data"] as List)
                .whereType<Map<String, dynamic>>()
                .map((x) => HostBookingHistory.fromJson(x))
                .toList()
            : <HostBookingHistory>[],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class HostBookingHistory {
  String bookId;
  String bookInvoice;
  double bookPrice; // supports decimal values
  bool bookIsPaid;
  bool bookIsCod;
  DateTime? bookAddedAt; // nullable safe parse
  String bookDetailsBtBookFrom;
  String bookDetailsBtBookTo;
  String bookingStatusBsTitle;
  dynamic bookingStatusBsCode;
  String userDetailsUserFullName;
  String userDetailsUserPnumber;

  HostBookingHistory({
    required this.bookId,
    required this.bookInvoice,
    required this.bookPrice,
    required this.bookIsPaid,
    required this.bookIsCod,
    required this.bookAddedAt,
    required this.bookDetailsBtBookFrom,
    required this.bookDetailsBtBookTo,
    required this.bookingStatusBsTitle,
    required this.bookingStatusBsCode,
    required this.userDetailsUserFullName,
    required this.userDetailsUserPnumber,
  });

  factory HostBookingHistory.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0;
    final rawPrice = json['book_price'];
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0;
    }

    DateTime? parsedAddedAt;
    final rawDate = json['book_added_at'];
    if (rawDate is String && rawDate.isNotEmpty) {
      try {
        parsedAddedAt = DateTime.parse(rawDate).toLocal();
      } catch (_) {}
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return HostBookingHistory(
      bookId: json['book_id']?.toString() ?? '',
      bookInvoice: json['book_invoice']?.toString() ?? '',
      bookPrice: parsedPrice,
      bookIsPaid: parseBool(json['book_is_paid']),
      bookIsCod: parseBool(json['book_is_cod']),
      bookAddedAt: parsedAddedAt,
      bookDetailsBtBookFrom: json['bookDetails.bt_book_from']?.toString() ?? '',
      bookDetailsBtBookTo: json['bookDetails.bt_book_to']?.toString() ?? '',
      bookingStatusBsTitle: json['bookingStatus.bs_title']?.toString() ?? '',
      bookingStatusBsCode: json['bookingStatus.bs_code'],
      userDetailsUserFullName:
          json['userDetails.user_fullName']?.toString() ?? '',
      userDetailsUserPnumber:
          json['userDetails.user_pnumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'book_invoice': bookInvoice,
        'book_price': bookPrice,
        'book_is_paid': bookIsPaid,
        'book_is_cod': bookIsCod,
        'book_added_at': bookAddedAt?.toUtc().toIso8601String(),
        'bookDetails.bt_book_from': bookDetailsBtBookFrom,
        'bookDetails.bt_book_to': bookDetailsBtBookTo,
        'bookingStatus.bs_title': bookingStatusBsTitle,
        'bookingStatus.bs_code': bookingStatusBsCode,
        'userDetails.user_fullName': userDetailsUserFullName,
        'userDetails.user_pnumber': userDetailsUserPnumber,
      };
}
