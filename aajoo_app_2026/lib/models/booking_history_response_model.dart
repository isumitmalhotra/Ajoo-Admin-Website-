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
      required this.book_price});

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
          book_price: json["book_price"]);

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
        "book_price": book_price
      };
}
