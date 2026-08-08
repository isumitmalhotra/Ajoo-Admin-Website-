// To parse this JSON data, do
//
//     final onGoingBookingResponse = onGoingBookingResponseFromJson(jsonString);

import 'dart:convert';

OnGoingBookingResponse onGoingBookingResponseFromJson(String str) =>
    OnGoingBookingResponse.fromJson(json.decode(str));

String onGoingBookingResponseToJson(OnGoingBookingResponse data) =>
    json.encode(data.toJson());

class OnGoingBookingResponse {
  bool success;
  String message;
  Data data;

  OnGoingBookingResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory OnGoingBookingResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json["data"];
    Data parsedData;
    if (rawData == null) {
      parsedData = Data(count: 0, bookings: []);
    } else if (rawData is List) {
      // API sometimes returns [] for no records
      parsedData = Data(count: 0, bookings: []);
    } else if (rawData is Map<String, dynamic>) {
      parsedData = Data.fromJson(rawData);
    } else {
      parsedData = Data(count: 0, bookings: []);
    }

    return OnGoingBookingResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: parsedData,
    );
  }

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
      };
}

class Data {
  int count;
  List<Booking> bookings;

  Data({
    required this.count,
    required this.bookings,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        count: (json["count"] is num)
            ? (json["count"] as num).toInt()
            : (json["count"] ?? 0),
        bookings: List<Booking>.from(
          ((json["bookings"] as List?) ?? [])
              .map((x) => Booking.fromJson(x as Map<String, dynamic>)),
        ),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "bookings": List<dynamic>.from(bookings.map((x) => x.toJson())),
      };
}

class Booking {
  int bookPriId;
  String bookId;
  String bookInvoice;
  int bookPrice;
  bool bookIsPaid;
  bool bookIsCod;
  int bookStatus;
  BookDetails? bookDetails;
  BookingStatus? bookingStatus;
  BookingProperty? bookingProperty;
  dynamic propertyImage;

  Booking({
    required this.bookPriId,
    required this.bookId,
    required this.bookInvoice,
    required this.bookPrice,
    required this.bookIsPaid,
    required this.bookIsCod,
    required this.bookStatus,
    this.bookDetails,
    this.bookingStatus,
    this.bookingProperty,
    this.propertyImage,
  });

  // Convenience getters for backward compatibility
  String get bookingStatusBsTitle => bookingStatus?.bsTitle ?? "";
  int get bookingPropertyPropertyId => bookingProperty?.propertyId ?? 0;
  String get bookingPropertyPropertyName => bookingProperty?.propertyName ?? "";
  int get bookingPropertyPropertyHostId => bookingProperty?.propertyHostId ?? 0;
  int get bookingPropertyHostDetailsUserId =>
      bookingProperty?.hostDetails?.userId ?? 0;
  String get bookingPropertyHostDetailsUserFullName =>
      bookingProperty?.hostDetails?.userFullName ?? "";
  String get bookingPropertyHostDetailsUserPnumber =>
      bookingProperty?.hostDetails?.userPnumber ?? "";

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        bookPriId: (json["book_pri_id"] as num?)?.toInt() ?? 0,
        bookId: json["book_id"]?.toString() ?? "",
        bookInvoice: json["book_invoice"]?.toString() ?? "",
        bookPrice: (json["book_price"] as num?)?.toInt() ?? 0,
        bookIsPaid: json["book_is_paid"] == true || json["book_is_paid"] == 1,
        bookIsCod: json["book_is_cod"] == true || json["book_is_cod"] == 1,
        bookStatus: (json["book_status"] as num?)?.toInt() ?? 0,
        bookDetails: json["bookDetails"] != null
            ? BookDetails.fromJson(json["bookDetails"] as Map<String, dynamic>)
            : null,
        bookingStatus: json["bookingStatus"] != null
            ? BookingStatus.fromJson(
                json["bookingStatus"] as Map<String, dynamic>)
            : null,
        bookingProperty: json["bookingProperty"] != null
            ? BookingProperty.fromJson(
                json["bookingProperty"] as Map<String, dynamic>)
            : null,
        propertyImage: json["property_image"],
      );

  Map<String, dynamic> toJson() => {
        "book_pri_id": bookPriId,
        "book_id": bookId,
        "book_invoice": bookInvoice,
        "book_price": bookPrice,
        "book_is_paid": bookIsPaid,
        "book_is_cod": bookIsCod,
        "book_status": bookStatus,
        "bookDetails": bookDetails?.toJson(),
        "bookingStatus": bookingStatus?.toJson(),
        "bookingProperty": bookingProperty?.toJson(),
        "property_image": propertyImage,
      };
}

class BookDetails {
  String btBookFrom;
  String btBookTo;

  BookDetails({
    required this.btBookFrom,
    required this.btBookTo,
  });

  factory BookDetails.fromJson(Map<String, dynamic> json) => BookDetails(
        btBookFrom: json["bt_book_from"]?.toString() ?? "",
        btBookTo: json["bt_book_to"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() => {
        "bt_book_from": btBookFrom,
        "bt_book_to": btBookTo,
      };
}

class BookingStatus {
  String bsTitle;

  BookingStatus({
    required this.bsTitle,
  });

  factory BookingStatus.fromJson(Map<String, dynamic> json) => BookingStatus(
        bsTitle: json["bs_title"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() => {
        "bs_title": bsTitle,
      };
}

class BookingProperty {
  int propertyId;
  String propertyName;
  int propertyHostId;
  HostDetails? hostDetails;

  BookingProperty({
    required this.propertyId,
    required this.propertyName,
    required this.propertyHostId,
    this.hostDetails,
  });

  factory BookingProperty.fromJson(Map<String, dynamic> json) =>
      BookingProperty(
        propertyId: (json["property_id"] as num?)?.toInt() ?? 0,
        propertyName: json["property_name"]?.toString() ?? "",
        propertyHostId: (json["property_host_id"] as num?)?.toInt() ?? 0,
        hostDetails: json["HostDetails"] != null
            ? HostDetails.fromJson(json["HostDetails"] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        "property_id": propertyId,
        "property_name": propertyName,
        "property_host_id": propertyHostId,
        "HostDetails": hostDetails?.toJson(),
      };
}

class HostDetails {
  int userId;
  String userFullName;
  String userPnumber;

  HostDetails({
    required this.userId,
    required this.userFullName,
    required this.userPnumber,
  });

  factory HostDetails.fromJson(Map<String, dynamic> json) => HostDetails(
        userId: (json["user_id"] as num?)?.toInt() ?? 0,
        userFullName: json["user_fullName"]?.toString() ?? "",
        userPnumber: json["user_pnumber"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "user_fullName": userFullName,
        "user_pnumber": userPnumber,
      };
}
