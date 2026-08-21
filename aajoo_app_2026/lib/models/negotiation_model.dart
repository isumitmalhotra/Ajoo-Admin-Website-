class NegotiationMessageModel {
  final String messageId; // unique identifier (message_id or id)
  final String propertyId;
  final String senderId;
  final String receiverId;
  final String messageText;
  final bool isOffer;
  final double? offerPrice;
  final String createdAt;
  final String userId;
  final String hostId;
  final bool isAccepted; // if offer accepted
  final String? acceptedBy; // who accepted
  final String? acceptedAt; // timestamp
  /// Settled by the engine rather than by the host pressing accept: the guest
  /// offered at or above the price the host had already agreed to take. Worth
  /// distinguishing, because "the host accepted your offer" would be putting
  /// words in their mouth — they were told, not asked.
  final bool autoAccepted;
  /// The deal code that carries the agreed price into checkout.
  final String? couponCode;

  NegotiationMessageModel({
    required this.messageId,
    required this.propertyId,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.isOffer,
    this.offerPrice,
    required this.createdAt,
    required this.userId,
    required this.hostId,
    this.isAccepted = false,
    this.acceptedBy,
    this.acceptedAt,
    this.autoAccepted = false,
    this.couponCode,
  });

  factory NegotiationMessageModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return NegotiationMessageModel(
      messageId: (json['message_id'] ?? json['id'] ?? json['offer_id'] ?? '')
          .toString(),
      propertyId: json['property_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      messageText: json['message_text'] ?? json['text'] ?? '',
      isOffer: parseBool(json['is_offer']),
      offerPrice: parseDouble(json['offer_price']),
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      userId: json['user_id']?.toString() ?? '',
      hostId: json['host_id']?.toString() ?? '',
      isAccepted: parseBool(json['is_accepted']),
      acceptedBy: json['accepted_by']?.toString(),
      acceptedAt: json['accepted_at']?.toString(),
      autoAccepted: parseBool(json['auto']),
      couponCode: json['coupon_code']?.toString(),
    );
  }

  NegotiationMessageModel copyWith({
    bool? isAccepted,
    String? acceptedBy,
    String? acceptedAt,
  }) {
    return NegotiationMessageModel(
      messageId: messageId,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      messageText: messageText,
      isOffer: isOffer,
      offerPrice: offerPrice,
      createdAt: createdAt,
      userId: userId,
      hostId: hostId,
      isAccepted: isAccepted ?? this.isAccepted,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      // Carried through, or a copyWith would quietly turn an auto-accepted
      // offer into one the host is credited with.
      autoAccepted: autoAccepted,
      couponCode: couponCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'property_id': propertyId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_text': messageText,
      'is_offer': isOffer,
      'offer_price': offerPrice,
      'created_at': createdAt,
      'user_id': userId,
      'host_id': hostId,
      'is_accepted': isAccepted,
      'accepted_by': acceptedBy,
      'accepted_at': acceptedAt,
    };
  }
}
