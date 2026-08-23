/// One negotiation thread on the GUEST's side.
///
/// The guest had no reader at all: they could POST an offer and then never
/// learn what became of it. The host had a list, the admin had a list, the
/// guest had a write-only door. When a host countered, the only signal was a
/// live socket event — present the screen and you saw it, miss the moment and
/// the counter was invisible for good.
///
/// GET /user/negotiations/list returns one entry per property+host pair with
/// the whole exchange in order, so both sides see the same conversation.
class GuestNegotiationMessage {
  final int offerId;

  /// 'you' or 'host' — who sent this one.
  final String from;
  final double price;
  final String message;
  final String status;
  final String? bookFrom;
  final String? bookTo;

  const GuestNegotiationMessage({
    required this.offerId,
    required this.from,
    required this.price,
    required this.message,
    required this.status,
    this.bookFrom,
    this.bookTo,
  });

  bool get mine => from == 'you';

  factory GuestNegotiationMessage.fromJson(Map<String, dynamic> j) =>
      GuestNegotiationMessage(
        offerId: _i(j['offerId']),
        from: j['from']?.toString() ?? 'you',
        price: _d(j['price']),
        message: j['message']?.toString() ?? '',
        status: j['status']?.toString() ?? 'pending',
        bookFrom: _s(j['bookFrom']),
        bookTo: _s(j['bookTo']),
      );
}

class GuestNegotiation {
  final int propertyId;
  final String propertyName;
  final String? propertyCity;

  /// The LISTED price. A host's floor and ideal never reach a guest, in any
  /// payload — that is the product's one non-negotiable rule.
  final double listedPrice;
  final int hostId;
  final String hostName;
  final List<GuestNegotiationMessage> messages;
  final double latestPrice;

  /// awaiting_you | awaiting_host | accepted | declined | expired
  final String status;
  final bool awaitingYou;

  /// The offer this guest can accept or decline right now, if any.
  final int? actionableOfferId;
  final String? bookFrom;
  final String? bookTo;

  const GuestNegotiation({
    required this.propertyId,
    required this.propertyName,
    this.propertyCity,
    required this.listedPrice,
    required this.hostId,
    required this.hostName,
    required this.messages,
    required this.latestPrice,
    required this.status,
    required this.awaitingYou,
    this.actionableOfferId,
    this.bookFrom,
    this.bookTo,
  });

  factory GuestNegotiation.fromJson(Map<String, dynamic> j) {
    final raw = j['messages'];
    return GuestNegotiation(
      propertyId: _i(j['propertyId']),
      propertyName: j['propertyName']?.toString() ?? 'Property',
      propertyCity: _s(j['propertyCity']),
      listedPrice: _d(j['listedPrice']),
      hostId: _i(j['hostId']),
      hostName: j['hostName']?.toString() ?? 'Host',
      messages: raw is List
          ? raw
              .whereType<Map>()
              .map((e) =>
                  GuestNegotiationMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      latestPrice: _d(j['latestPrice']),
      status: j['status']?.toString() ?? 'awaiting_host',
      awaitingYou: j['awaitingYou'] == true,
      actionableOfferId:
          j['actionableOfferId'] == null ? null : _i(j['actionableOfferId']),
      bookFrom: _s(j['bookFrom']),
      bookTo: _s(j['bookTo']),
    );
  }
}

double _d(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _i(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String? _s(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}
