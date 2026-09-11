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

  /// When this price was named. Null on rows written before it was sent.
  final DateTime? createdAt;

  const GuestNegotiationMessage({
    required this.offerId,
    required this.from,
    required this.price,
    required this.message,
    required this.status,
    this.bookFrom,
    this.bookTo,
    this.createdAt,
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
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal(),
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

  /// The same messages, grouped into the negotiations they belong to.
  ///
  /// A stay can be negotiated more than once, weeks apart, and the whole
  /// history arrives as one list. Without this the screen ran two separate
  /// conversations together as though they were one argument. The grouping
  /// is the SERVER's — the same one that decides how many offers are left —
  /// so the transcript and the allowance can never disagree.
  ///
  /// Falls back to one group on an older payload.
  final List<List<GuestNegotiationMessage>> sessions;
  final double latestPrice;

  /// awaiting_you | awaiting_host | accepted | declined | expired
  final String status;
  final bool awaitingYou;

  /// The offer this guest can accept, decline or counter right now, if any.
  final int? actionableOfferId;

  /// Offers each side has sent, and the ceiling both are held to. A
  /// negotiation used to be one round each way and then stuck.
  /// How many prices this side has named in the negotiation that is running.
  /// Reported, never compared: the three-offer allowance was removed on
  /// 2026-09-12 at the client's instruction, and the server no longer sends
  /// a `maxRounds` to subtract it from.
  final int roundsYou;

  /// Whether this guest may send another price into the thread right now.
  final bool canCounter;
  final String? bookFrom;
  final String? bookTo;

  /// Party size the price was struck for. Null on offers made before the
  /// server stored it — the listing must not invent a number from that.
  final int? guests;

  /// How long this host says they take to answer, in hours.
  ///
  /// The platform answers a guest's FIRST offer within ninety seconds using
  /// the host's own ideal price. Past that the thread belongs to the two of
  /// them, so "Waiting on host" is a real wait — and with no number attached
  /// it reads as "possibly for ever".
  ///
  /// Null when the host never gave one, and then nothing is shown: a duration
  /// nobody promised is worse than silence.
  final int? hostResponseHours;

  /// The host has had their ninety seconds and has not answered.
  ///
  /// The server's call, on the server's clock. This app cannot time the
  /// window itself without trusting the device clock against the API, and
  /// those have disagreed before.
  final bool hostAway;

  const GuestNegotiation({
    required this.propertyId,
    required this.propertyName,
    this.propertyCity,
    required this.listedPrice,
    required this.hostId,
    required this.hostName,
    required this.messages,
    this.sessions = const [],
    required this.latestPrice,
    required this.status,
    required this.awaitingYou,
    this.actionableOfferId,
    this.roundsYou = 0,
    this.canCounter = false,
    this.bookFrom,
    this.bookTo,
    this.guests,
    this.hostResponseHours,
    this.hostAway = false,
  });

  factory GuestNegotiation.fromJson(Map<String, dynamic> j) {
    final raw = j['messages'];
    final rawSessions = j['sessions'];
    List<List<GuestNegotiationMessage>> groups = const [];
    if (rawSessions is List) {
      groups = rawSessions
          .whereType<Map>()
          .map((g) => (g['messages'] is List)
              ? (g['messages'] as List)
                  .whereType<Map>()
                  .map((m) => GuestNegotiationMessage.fromJson(
                      Map<String, dynamic>.from(m)))
                  .toList()
              : <GuestNegotiationMessage>[])
          .where((g) => g.isNotEmpty)
          .toList();
    }
    return GuestNegotiation(
      propertyId: _i(j['propertyId']),
      propertyName: j['propertyName']?.toString() ?? 'Property',
      propertyCity: _s(j['propertyCity']),
      listedPrice: _d(j['listedPrice']),
      hostId: _i(j['hostId']),
      hostName: j['hostName']?.toString() ?? 'Host',
      // Absent, zero or unparseable all mean "the host never said".
      hostAway: j['hostAway'] == true || j['hostAway']?.toString() == '1',
      hostResponseHours: (int.tryParse(j['hostResponseHours']?.toString() ?? '') ?? 0) > 0
          ? int.parse(j['hostResponseHours'].toString())
          : null,
      sessions: groups,
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
      roundsYou: _i(j['roundsYou']),
      canCounter: j['canCounter'] == true,
      bookFrom: _s(j['bookFrom']),
      bookTo: _s(j['bookTo']),
      guests: j['guests'] == null ? null : _i(j['guests']),
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
