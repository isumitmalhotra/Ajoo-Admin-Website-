// To parse this JSON data, do
//
//     final bookingHistoryResponse = bookingHistoryResponseFromJson(jsonString);

import 'dart:convert';

BookingHistoryResponse bookingHistoryResponseFromJson(String str) =>
    BookingHistoryResponse.fromJson(json.decode(str));

String bookingHistoryResponseToJson(BookingHistoryResponse data) =>
    json.encode(data.toJson());

class BookingHistoryResponse {
  bool success;
  String message;
  List<BookingHistoryData> data;

  BookingHistoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BookingHistoryResponse.fromJson(Map<String, dynamic> json) =>
      BookingHistoryResponse(
        success: json["success"],
        message: json["message"],
        data: List<BookingHistoryData>.from(
            json["data"].map((x) => BookingHistoryData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class BookingHistoryData {
  String? bookId;
  String? bookInvoice;
  int? bookPropId;
  DateTime? bookAddedAt;
  String? bookingPropertyPropertyName;
  String? bookingPropertyPropertyAddress;
  String? bookingPropertyPropertyEmail;
  String? bookingPropertyPropertyDesc;
  String? bookingStatusBsTitle;
  String? bookDetailsBtBookFrom;
  String? bookDetailsBtBookTo;
  dynamic book_price;
  // /user/booking-history has always returned these four; the model dropped
  // them, so a guest's own booking could show dates and a status but never
  // what they actually paid or how many guests it was for.
  double? bookTotalAmt;
  bool bookIsPaid;
  bool bookIsCod;
  int? bookNoOfGuests;

  /// The stay's cover photo. /user/booking-history has attached this for a
  /// while (it prefers the cover image and falls back to the first gallery
  /// shot); the model dropped it, so every booking card had to be text-only.
  /// Null when the listing genuinely has no photo — the card draws a
  /// placeholder rather than a broken image.
  String? coverImage;

  BookingHistoryData(
      {this.bookId,
      this.bookInvoice,
      this.bookPropId,
      this.bookAddedAt,
      this.bookingPropertyPropertyName,
      this.bookingPropertyPropertyAddress,
      this.bookingPropertyPropertyEmail,
      this.bookingPropertyPropertyDesc,
      this.bookingStatusBsTitle,
      this.bookDetailsBtBookFrom,
      this.bookDetailsBtBookTo,
      required this.book_price,
      this.bookTotalAmt,
      this.bookIsPaid = false,
      this.bookIsCod = false,
      this.bookNoOfGuests,
      this.coverImage});

  factory BookingHistoryData.fromJson(Map<String, dynamic> json) =>
      BookingHistoryData(
          bookId: json["book_id"],
          bookInvoice: json["book_invoice"],
          bookPropId: json["book_prop_id"],
          bookAddedAt: DateTime.parse(json["book_added_at"]),
          bookingPropertyPropertyName: json["bookingProperty.property_name"],
          bookingPropertyPropertyAddress:
              json["bookingProperty.property_address"],
          bookingPropertyPropertyEmail: json["bookingProperty.property_email"],
          bookingPropertyPropertyDesc: json["bookingProperty.property_desc"],
          bookingStatusBsTitle: json["bookingStatus.bs_title"],
          bookDetailsBtBookFrom: json["bookDetails.bt_book_from"],
          bookDetailsBtBookTo: json["bookDetails.bt_book_to"],
          book_price: json["book_price"],
          bookTotalAmt: _toDouble(json["book_total_amt"]),
          // MySQL sends these as 1/0, so a plain cast to bool would throw.
          bookIsPaid: _toBool(json["book_is_paid"]),
          bookIsCod: _toBool(json["book_is_cod"]),
          bookNoOfGuests: _toInt(json["book_no_of_guests"]),
          coverImage: json["coverImage"]);

  Map<String, dynamic> toJson() => {
        "book_id": bookId,
        "book_invoice": bookInvoice,
        "book_prop_id": bookPropId,
        "book_added_at": bookAddedAt?.toIso8601String(),
        "bookingProperty.property_name": bookingPropertyPropertyName,
        "bookingProperty.property_address": bookingPropertyPropertyAddress,
        "bookingProperty.property_email": bookingPropertyPropertyEmail,
        "bookingProperty.property_desc": bookingPropertyPropertyDesc,
        "bookingStatus.bs_title": bookingStatusBsTitle,
        "bookDetails.bt_book_from": bookDetailsBtBookFrom,
        "bookDetails.bt_book_to": bookDetailsBtBookTo,
        "book_price": book_price,
        "book_total_amt": bookTotalAmt,
        "book_is_paid": bookIsPaid,
        "book_is_cod": bookIsCod,
        "book_no_of_guests": bookNoOfGuests,
        "coverImage": coverImage
      };
}

double? _toDouble(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

int? _toInt(dynamic v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v == 1;
  final s = v?.toString().toLowerCase();
  return s == '1' || s == 'true';
}
