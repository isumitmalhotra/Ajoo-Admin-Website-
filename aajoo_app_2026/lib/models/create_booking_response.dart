import 'dart:convert';

BookingResponse onlineBookingResponseFromJson(String str) =>
    BookingResponse.fromJson(json.decode(str));

String onlineBookingResponseToJson(BookingResponse data) =>
    json.encode(data.toJson());

class BookingResponse {
  bool success;
  String message;
  Data data;

  BookingResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) =>
      BookingResponse(
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
  Booking booking;

  Data({
    required this.booking,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        booking: Booking.fromJson(json["booking"]),
      );

  Map<String, dynamic> toJson() => {
        "booking": booking.toJson(),
      };
}

class Booking {
  String bookId;
  Order? order;

  /// Wallet split (audit C-9). walletPaid true = the wallet covered the whole
  /// stay and there is no gateway order to open; walletApplied/payable carry
  /// the split so the UI can say exactly what happened.
  bool walletPaid;
  double walletApplied;
  double payable;

  Booking({
    required this.bookId,
    this.order,
    this.walletPaid = false,
    this.walletApplied = 0,
    this.payable = 0,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        bookId: json["book_id"],
        order: json["order"] != null ? Order.fromJson(json["order"]) : null,
        walletPaid: json["walletPaid"] == true,
        walletApplied:
            double.tryParse('${json["walletApplied"] ?? 0}') ?? 0,
        payable: double.tryParse('${json["payable"] ?? 0}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "book_id": bookId,
        "order": order?.toJson(),
      };
}

class Order {
  int amount;
  int amountDue;
  int amountPaid;
  int attempts;
  int createdAt;
  String currency;
  String entity;
  String id;
  List<dynamic> notes;
  dynamic offerId;
  String receipt;
  String status;

  Order({
    required this.amount,
    required this.amountDue,
    required this.amountPaid,
    required this.attempts,
    required this.createdAt,
    required this.currency,
    required this.entity,
    required this.id,
    required this.notes,
    required this.offerId,
    required this.receipt,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        amount: json["amount"],
        amountDue: json["amount_due"],
        amountPaid: json["amount_paid"],
        attempts: json["attempts"],
        createdAt: json["created_at"],
        currency: json["currency"],
        entity: json["entity"],
        id: json["id"],
        notes: List<dynamic>.from(json["notes"].map((x) => x)),
        offerId: json["offer_id"],
        receipt: json["receipt"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "amount_due": amountDue,
        "amount_paid": amountPaid,
        "attempts": attempts,
        "created_at": createdAt,
        "currency": currency,
        "entity": entity,
        "id": id,
        "notes": List<dynamic>.from(notes.map((x) => x)),
        "offer_id": offerId,
        "receipt": receipt,
        "status": status,
      };
}
