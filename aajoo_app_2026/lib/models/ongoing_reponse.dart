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

/// DECIMAL columns arrive as a number OR a string depending on the driver, so
/// every money field is parsed rather than cast. Null and unparseable both
/// mean "not sent", which is 0 rather than a crash.
double? _money(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class Booking {
  int bookPriId;
  String bookId;
  String bookInvoice;
  /// The room subtotal, BEFORE tax. Never show this on its own — see
  /// [bookTotalAmt]. It is the "Room charge" line of a breakdown, nothing
  /// more.
  int bookPrice;

  /// GST on this booking.
  double bookTax;

  /// What the guest actually owes: room + tax − any discount. This is the
  /// number every screen leads with.
  ///
  /// Falls back to the subtotal only when the server sends no total at all,
  /// which is what older responses did — and showing the subtotal labelled
  /// "Amount" is exactly how the booking detail came to say Rs 4,000 for a
  /// stay the confirmation had just called Rs 4,200.
  double bookTotalAmt;

  /// Any coupon or negotiated saving already taken off the subtotal.
  double bookDiscountAmt;

  bool bookIsPaid;
  bool bookIsCod;
  int bookStatus;

  /// When the row was created. Distinguishes a live reservation from an
  /// abandoned card checkout, which is created before Razorpay opens.
  DateTime? bookAddedAt;
  BookDetails? bookDetails;
  BookingStatus? bookingStatus;
  BookingProperty? bookingProperty;
  dynamic propertyImage;

  Booking({
    required this.bookPriId,
    required this.bookId,
    required this.bookInvoice,
    required this.bookPrice,
    this.bookTax = 0,
    double? bookTotalAmt,
    this.bookDiscountAmt = 0,
    required this.bookIsPaid,
    required this.bookIsCod,
    required this.bookStatus,
    this.bookAddedAt,
    this.bookDetails,
    this.bookingStatus,
    this.bookingProperty,
    this.propertyImage,
  }) : bookTotalAmt = bookTotalAmt ?? bookPrice.toDouble();

  /// Taxes and fees inside [bookTotalAmt].
  ///
  /// Uses the stored figure when the server sent one; otherwise derives it,
  /// because total − subtotal + discount IS the tax by construction. Never
  /// negative: a total that is somehow below the subtotal means the data is
  /// odd, not that the guest is owed a negative tax.
  double get taxesAndFees {
    if (bookTax > 0) return bookTax;
    final derived = bookTotalAmt - bookPrice + bookDiscountAmt;
    return derived > 0 ? derived : 0;
  }

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
  double? get bookingPropertyLatitude => bookingProperty?.latitude;
  double? get bookingPropertyLongitude => bookingProperty?.longitude;
  String get bookingPropertyAddress {
    final p = bookingProperty;
    if (p == null) return "";
    return [p.propertyAddress, p.propertyCity]
        .where((e) => e.isNotEmpty)
        .join(", ");
  }

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        bookPriId: (json["book_pri_id"] as num?)?.toInt() ?? 0,
        bookId: json["book_id"]?.toString() ?? "",
        bookInvoice: json["book_invoice"]?.toString() ?? "",
        bookPrice: (json["book_price"] as num?)?.toInt() ?? 0,
        // Loosely parsed: these are DECIMAL columns and Sequelize hands some
        // of them back as strings, so a blind cast drops them to zero.
        bookTax: _money(json["book_tax"]) ?? 0,
        bookTotalAmt: _money(json["book_total_amt"]),
        bookDiscountAmt: _money(json["book_discount_amt"]) ?? 0,
        bookIsPaid: json["book_is_paid"] == true || json["book_is_paid"] == 1,
        bookIsCod: json["book_is_cod"] == true || json["book_is_cod"] == 1,
        bookStatus: (json["book_status"] as num?)?.toInt() ?? 0,
        bookAddedAt: DateTime.tryParse(json["book_added_at"]?.toString() ?? ""),
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
        "book_added_at": bookAddedAt?.toIso8601String(),
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

  /// Address and coordinates.
  ///
  /// The ongoing-bookings endpoint has always sent these — property_city,
  /// property_address, property_latitude, property_longitude are all in its
  /// select list — and this model dropped them on the floor. So the screen
  /// made a SECOND request just to find out where the property was, every
  /// time the guest tapped the location button, to hand off to the Maps app.
  String propertyCity;
  String propertyAddress;
  double? latitude;
  double? longitude;

  HostDetails? hostDetails;

  BookingProperty({
    required this.propertyId,
    required this.propertyName,
    required this.propertyHostId,
    this.propertyCity = "",
    this.propertyAddress = "",
    this.latitude,
    this.longitude,
    this.hostDetails,
  });

  // Sent as strings by the backend, so tryParse rather than a cast.
  static double? _coord(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  factory BookingProperty.fromJson(Map<String, dynamic> json) =>
      BookingProperty(
        propertyId: (json["property_id"] as num?)?.toInt() ?? 0,
        propertyName: json["property_name"]?.toString() ?? "",
        propertyHostId: (json["property_host_id"] as num?)?.toInt() ?? 0,
        propertyCity: json["property_city"]?.toString() ?? "",
        propertyAddress: json["property_address"]?.toString() ?? "",
        latitude: _coord(json["property_latitude"]),
        longitude: _coord(json["property_longitude"]),
        hostDetails: json["HostDetails"] != null
            ? HostDetails.fromJson(json["HostDetails"] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        "property_id": propertyId,
        "property_name": propertyName,
        "property_host_id": propertyHostId,
        "property_city": propertyCity,
        "property_address": propertyAddress,
        "property_latitude": latitude,
        "property_longitude": longitude,
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
