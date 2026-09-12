import 'package:rent_home/utils/transcript_label.dart';

/// One negotiation thread on the host's side (A-70).
///
/// `/host/negotiations/list` has existed since the negotiation feature
/// shipped, and nothing in the app ever called it: a host could only find an
/// offer by catching its push notification. This is the model for that
/// endpoint — one row per property/guest pair, most recent offer first, which
/// is how the server already collapses the threads.
class HostNegotiation {
  final int offerId;
  final int propertyId;
  final String propertyName;
  final double originalPrice;
  final int renterId;
  final String renterName;
  final double offerPrice;
  final String message;

  /// pending | accepted | declined | countered — whatever the server stored.
  final String status;
  final DateTime? createdAt;

  /// The stay the guest is asking for, DD-MM-YYYY, so the host can see what
  /// they would be sanctioning. Null on older offers made before dates were
  /// carried on the offer.
  final String? bookFrom;
  final String? bookTo;

  /// The guest's offer came in under the minimum this host set.
  ///
  /// HOST PAYLOAD ONLY, and it must stay that way — it says which side of
  /// the floor an offer landed on, and a guest able to ask that twice has
  /// bracketed the floor. The escalation email and the push have said it
  /// since 2026-09-09; the screen the host decides on said nothing.
  final bool belowMinimum;

  const HostNegotiation({
    required this.offerId,
    required this.propertyId,
    required this.propertyName,
    required this.originalPrice,
    required this.renterId,
    required this.renterName,
    required this.offerPrice,
    required this.message,
    required this.status,
    this.createdAt,
    this.bookFrom,
    this.bookTo,
    this.belowMinimum = false,
    this.rounds = 0,
    this.messages = const [],
  });

  /// How many offers have crossed in this thread, and the ceiling both sides
  /// are held to.
  ///
  /// The host's card showed the latest price with no sense of whether this
  /// was an opening bid or the fourth round. The list endpoint returns the
  /// whole `messages` array, so the count was there to be read.
  ///
  /// There is no denominator any more: the three-counter allowance was removed
  /// on 2026-09-12 at the client's instruction, so "Round 2 of 3" would be
  /// promising a ceiling that no longer exists.
  final int rounds;

  /// "Round 2" — omitted when nothing has been exchanged yet.
  String? get roundLabel => rounds <= 0 ? null : 'Round $rounds';

  /// The whole exchange, oldest first.
  ///
  /// The endpoint has always returned it and this model counted the array and
  /// threw it away, so the host's phone showed the latest price and nothing
  /// about how it got there — no sign of what the platform had already
  /// answered in their name. The website has shown the transcript since the
  /// list screen was built, and a host reading one thread on two devices was
  /// reading two different things.
  final List<HostNegotiationMessage> messages;

  bool get isPending => status.toLowerCase() == 'pending';

  /// How far below the asking price the guest is, as a percentage. Null when
  /// there is no asking price to compare against — never 0, which would read
  /// as "they offered full price".
  double? get discountPercent {
    if (originalPrice <= 0 || offerPrice <= 0) return null;
    return ((originalPrice - offerPrice) / originalPrice) * 100;
  }

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _i(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory HostNegotiation.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['createdAt'];
    if (raw is String && raw.isNotEmpty) {
      try {
        created = DateTime.parse(raw).toLocal();
      } catch (_) {}
    }
    String? nonEmpty(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    return HostNegotiation(
      offerId: _i(json['offerId']),
      propertyId: _i(json['propertyId']),
      propertyName: json['propertyName']?.toString() ?? 'Property',
      originalPrice: _d(json['originalPrice']),
      renterId: _i(json['renterId']),
      renterName: json['renterName']?.toString() ?? 'Guest',
      offerPrice: _d(json['offerPrice']),
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: created,
      bookFrom: nonEmpty(json['bookFrom']),
      bookTo: nonEmpty(json['bookTo']),
      // Absent on an older payload, and absent means NOT below — never
      // guess an alarm from a missing field.
      belowMinimum: json['belowMinimum'] == true,
      // Every offer that has crossed, from either side.
      rounds: json['messages'] is List ? (json['messages'] as List).length : 0,
      messages: json['messages'] is List
          ? (json['messages'] as List)
              .whereType<Map>()
              .map((m) => HostNegotiationMessage.fromJson(
                  Map<String, dynamic>.from(m)))
              .toList()
          : const [],
    );
  }
}


/// One message in a host's negotiation thread.
///
/// `automatic` is the whole reason this is worth rendering: the platform
/// answers round one in the host's name, and a host must be able to tell which
/// words in their own conversation are theirs.
class HostNegotiationMessage {
  final int offerId;

  /// "you" for the host, anything else for the guest.
  final String from;
  final double price;
  final String message;

  /// pending | countered | accepted | declined | expired
  final String status;

  /// Written by the platform on the host's behalf.
  final bool automatic;
  final DateTime? createdAt;

  const HostNegotiationMessage({
    required this.offerId,
    required this.from,
    required this.price,
    required this.message,
    required this.status,
    this.automatic = false,
    this.createdAt,
  });

  bool get mine => from == 'you';

  /// What happened TO this message. Shared with the guest list and with both
  /// website screens — see utils/transcript_label.dart.
  String get label => transcriptLabel(
        mine: mine,
        status: status,
        viewer: TranscriptViewer.host,
        automatic: automatic,
      );

  factory HostNegotiationMessage.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => double.tryParse((v ?? 0).toString()) ?? 0;
    int i(dynamic v) => int.tryParse((v ?? 0).toString()) ?? 0;
    return HostNegotiationMessage(
      offerId: i(j['offerId']),
      from: j['from']?.toString() ?? 'them',
      price: d(j['price']),
      message: j['message']?.toString() ?? '',
      status: j['status']?.toString() ?? 'pending',
      // The server sends a real boolean; older payloads send nothing, and
      // "nothing" must read as "the host wrote this" rather than the reverse —
      // labelling a host's own counter "Answered for you" would be worse than
      // leaving an automatic one unmarked.
      automatic: j['automatic'] == true,
      createdAt: j['createdAt'] == null
          ? null
          : DateTime.tryParse(j['createdAt'].toString()),
    );
  }
}
