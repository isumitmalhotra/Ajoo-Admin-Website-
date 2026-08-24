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

  /// The NUMERIC primary id. Distinct from [bookId], which is the human
  /// reference ("B618787"): /host/confirm-book takes this one, and the API has
  /// always returned it — the model simply dropped it, which is why the app
  /// could not approve a booking.
  int? bookPriId;
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

  /// Which listing was booked, and by whom (A-68/A-69).
  ///
  /// The host's list carried neither until 2026-08-13 — the endpoint selected
  /// six booking columns and no ids — so a host could see that a booking
  /// existed and nothing about what was booked or who to message. 0 means the
  /// server has not been deployed with the wider query yet; callers should
  /// treat it as "not available" rather than as a real id.
  int bookPropId;
  int bookUserId;
  double bookTotalAmt;
  int bookNoOfGuests;
  String propertyName;
  String propertyAddress;

  HostBookingHistory({
    required this.bookId,
    this.bookPriId,
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
    this.bookPropId = 0,
    this.bookUserId = 0,
    this.bookTotalAmt = 0,
    this.bookNoOfGuests = 0,
    this.propertyName = '',
    this.propertyAddress = '',
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

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return HostBookingHistory(
      bookId: json['book_id']?.toString() ?? '',
      // 0 means the field was absent — keep that as null so the UI can tell
      // "cannot confirm this" apart from "confirm booking 0".
      bookPriId: parseInt(json['book_pri_id']) == 0
          ? null
          : parseInt(json['book_pri_id']),
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
      bookPropId: parseInt(json['book_prop_id']),
      bookUserId: parseInt(json['book_user_id']),
      bookTotalAmt: parseDouble(json['book_total_amt']),
      bookNoOfGuests: parseInt(json['book_no_of_guests']),
      propertyName:
          json['bookingProperty.property_name']?.toString() ?? '',
      propertyAddress:
          json['bookingProperty.property_address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'book_pri_id': bookPriId,
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
        'book_prop_id': bookPropId,
        'book_user_id': bookUserId,
        'book_total_amt': bookTotalAmt,
        'book_no_of_guests': bookNoOfGuests,
        'bookingProperty.property_name': propertyName,
        'bookingProperty.property_address': propertyAddress,
      };
}
