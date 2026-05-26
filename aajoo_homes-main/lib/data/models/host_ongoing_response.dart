// To parse this JSON data, do
//
//     final hostOnGoingBookingResponse = hostOnGoingBookingResponseFromJson(jsonString);

import 'dart:convert';

HostOnGoingBookingResponse hostOnGoingBookingResponseFromJson(String str) => HostOnGoingBookingResponse.fromJson(json.decode(str));

String hostOnGoingBookingResponseToJson(HostOnGoingBookingResponse data) => json.encode(data.toJson());

class HostOnGoingBookingResponse {
    bool success;
    String message;
    Data data;

    HostOnGoingBookingResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    factory HostOnGoingBookingResponse.fromJson(Map<String, dynamic> json) => HostOnGoingBookingResponse(
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
    int totalcount;
    int records;
    List<Booking> bookings;

    Data({
        required this.totalcount,
        required this.records,
        required this.bookings,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        totalcount: json["totalcount"],
        records: json["records"],
        bookings: List<Booking>.from(json["bookings"].map((x) => Booking.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "totalcount": totalcount,
        "records": records,
        "bookings": List<dynamic>.from(bookings.map((x) => x.toJson())),
    };
}

class Booking {
    int bookPriId;
    String bookId;
    int bookPropId;
    int bookUserId;
    int bookHostId;
    int bookStatus;
    String bookDetailsBtBookFrom;
    String bookDetailsBtBookTo;
    String userDetailsUserPnumber;
    String userDetailsUserFullName;
    String bookingStatusBsTitle;
    dynamic bookingStatusBsCode;
    List<dynamic> attachments;

    Booking({
        required this.bookPriId,
        required this.bookId,
        required this.bookPropId,
        required this.bookUserId,
        required this.bookHostId,
        required this.bookStatus,
        required this.bookDetailsBtBookFrom,
        required this.bookDetailsBtBookTo,
        required this.userDetailsUserPnumber,
        required this.userDetailsUserFullName,
        required this.bookingStatusBsTitle,
        required this.bookingStatusBsCode,
        required this.attachments,
    });

    factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        bookPriId: json["book_pri_id"],
        bookId: json["book_id"],
        bookPropId: json["book_prop_id"],
        bookUserId: json["book_user_id"],
        bookHostId: json["book_host_id"],
        bookStatus: json["book_status"],
        bookDetailsBtBookFrom: json["bookDetails.bt_book_from"],
        bookDetailsBtBookTo: json["bookDetails.bt_book_to"],
        userDetailsUserPnumber: json["userDetails.user_pnumber"],
        userDetailsUserFullName: json["userDetails.user_fullName"],
        bookingStatusBsTitle: json["bookingStatus.bs_title"],
        bookingStatusBsCode: json["bookingStatus.bs_code"],
        attachments: List<dynamic>.from(json["attachments"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "book_pri_id": bookPriId,
        "book_id": bookId,
        "book_prop_id": bookPropId,
        "book_user_id": bookUserId,
        "book_host_id": bookHostId,
        "book_status": bookStatus,
        "bookDetails.bt_book_from": bookDetailsBtBookFrom,
        "bookDetails.bt_book_to": bookDetailsBtBookTo,
        "userDetails.user_pnumber": userDetailsUserPnumber,
        "userDetails.user_fullName": userDetailsUserFullName,
        "bookingStatus.bs_title": bookingStatusBsTitle,
        "bookingStatus.bs_code": bookingStatusBsCode,
        "attachments": List<dynamic>.from(attachments.map((x) => x)),
    };
}
