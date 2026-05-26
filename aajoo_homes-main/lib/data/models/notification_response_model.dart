// To parse this JSON data, do
//
//     final appNotificationResponse = appNotificationResponseFromJson(jsonString);

import 'dart:convert';

AppNotificationResponse appNotificationResponseFromJson(String str) =>
    AppNotificationResponse.fromJson(json.decode(str));

String appNotificationResponseToJson(AppNotificationResponse data) =>
    json.encode(data.toJson());

class AppNotificationResponse {
  bool success;
  String message;
  Data data;

  AppNotificationResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AppNotificationResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json["data"];
    final parsedData = (rawData is Map<String, dynamic>)
        ? Data.fromJson(rawData)
        : Data(notifications: []);

    return AppNotificationResponse(
      success: json["success"] == true,
      message: json["message"]?.toString() ?? "",
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
  List<AppNotification> notifications;

  Data({
    required this.notifications,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    // API may return key as "notifications" OR legacy misspelled "notifiations"
    final list = (json['notifications'] ?? json['notifiations']);
    final items = (list is List)
        ? list
            .whereType<Map<String, dynamic>>()
            .map((m) => AppNotification.fromJson(m))
            .toList()
        : <AppNotification>[];
    return Data(notifications: items);
  }

  Map<String, dynamic> toJson() => {
        "notifications": notifications.map((x) => x.toJson()).toList(),
      };
}

class AppNotification {
  int unId;
  String unTitle;
  String unMessage;
  DateTime? createdAt; // made nullable to avoid parse crashes
  int unIsRead;
  int? unPropId;
  NotificationPayload? payload;

  AppNotification({
    required this.unId,
    required this.unTitle,
    required this.unMessage,
    required this.createdAt,
    required this.unIsRead,
    required this.unPropId,
    this.payload,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['createdAt'];
    if (rawDate is String && rawDate.isNotEmpty) {
      try {
        parsedDate = DateTime.parse(rawDate).toLocal();
      } catch (_) {}
    }

    return AppNotification(
      unId: (json['un_id'] as num?)?.toInt() ?? 0,
      unTitle: json['un_title']?.toString() ?? '',
      unMessage: json['un_message']?.toString() ?? '',
      createdAt: parsedDate,
      unIsRead: (json['un_is_read'] as num?)?.toInt() ?? 0,
      unPropId: (json['un_propId'] is num)
          ? (json['un_propId'] as num).toInt()
          : (json['un_propId'] is String &&
                  json['un_propId'].toString().isNotEmpty
              ? int.tryParse(json['un_propId'].toString())
              : null),
      payload: (json['payload'] is Map<String, dynamic>)
          ? NotificationPayload.fromJson(
              json['payload'] as Map<String, dynamic>)
          : (json['un_payload'] is Map<String, dynamic>)
              ? NotificationPayload.fromJson(
                  json['un_payload'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'un_id': unId,
        'un_title': unTitle,
        'un_message': unMessage,
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'un_is_read': unIsRead,
        'un_propId': unPropId,
        if (payload != null) 'un_payload': payload!.toJson(),
      };
}

class NotificationPayload {
  String? route;
  String? type;
  String? propertyId; // Changed to String to match API response
  String? userId; // Changed to String to match API response
  String? receiverId;
  String? hostId;
  String? lat;
  String? long;
  String? room;
  String? roomId;
  String? offerId;
  String? accepterId;

  NotificationPayload({
    this.route,
    this.type,
    this.propertyId,
    this.userId,
    this.receiverId,
    this.hostId,
    this.lat,
    this.long,
    this.room,
    this.roomId,
    this.offerId,
    this.accepterId,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) =>
      NotificationPayload(
        route: json['route']?.toString(),
        type: json['type']?.toString(),
        propertyId: json['propertyId']?.toString(),
        userId: json['userId']?.toString(),
        receiverId: json['receiverId']?.toString(),
        hostId: json['hostId']?.toString(),
        lat: json['lat']?.toString(),
        long: json['long']?.toString(),
        room: json['room']?.toString(),
        roomId: json['room_id']?.toString(),
        offerId: json['offer_id']?.toString(),
        accepterId: json['accepter_id']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (route != null) 'route': route,
        if (type != null) 'type': type,
        if (propertyId != null) 'propertyId': propertyId,
        if (userId != null) 'userId': userId,
        if (receiverId != null) 'receiverId': receiverId,
        if (hostId != null) 'hostId': hostId,
        if (lat != null) 'lat': lat,
        if (long != null) 'long': long,
        if (room != null) 'room': room,
        if (roomId != null) 'room_id': roomId,
        if (offerId != null) 'offer_id': offerId,
        if (accepterId != null) 'accepter_id': accepterId,
      };
}
