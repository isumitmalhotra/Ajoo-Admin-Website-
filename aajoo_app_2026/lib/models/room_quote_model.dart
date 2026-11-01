// What a by-room property costs, as the server works it out.
//
// Room-level booking, phase 2. A guesthouse sells units out of room types, so
// the single price on a property page becomes a table of them — and a total
// for whatever the guest picks.
//
// ── NOTHING HERE DOES ARITHMETIC ────────────────────────────────────────────
//
// Every figure is read, never derived. Not even "units x per-room price",
// which looks harmless and is not: GST on accommodation is banded per room per
// night, so two ₹2,400 rooms are two 5% supplies while their ₹9,600 sum would
// look like an 18% one. The server already knows that, and utils/gst.dart
// exists in this app precisely because a client that reinvents the slab rule
// gets it wrong — a ₹4,000 room over two nights is ₹8,000 for the stay and
// still 5%.
//
// So these classes parse. The web client holds the same line, for the same
// reason, in services/customerApi.ts.

/// One room type, priced for the chosen dates.
class RoomTypeOffer {
  const RoomTypeOffer({
    required this.roomTypeId,
    required this.name,
    this.description,
    this.beds = const [],
    this.photos = const [],
    this.totalGuests,
    this.guestsIncluded,
    this.extraGuestPrice = 0,
    this.quantity = 0,
    this.free = 0,
    this.soldOut = false,
    this.priced = false,
    this.nightCount = 0,
    this.perUnitGrandTotal = 0,
    this.longStayLabel,
  });

  final int roomTypeId;
  final String name;
  final String? description;

  /// `[{type, count}]`, already normalised by the server.
  final List<Map<String, dynamic>> beds;

  /// At most three. Client decision, 2026-10-21.
  final List<String> photos;

  final int? totalGuests;
  final int? guestsIncluded;
  final num extraGuestPrice;

  /// How many the host has, and how many are left for these dates.
  final int quantity;
  final int free;
  final bool soldOut;

  /// False when the host has no price for these dates.
  ///
  /// NOT the same as sold out, and the difference matters on screen: a room
  /// with no price must never render as ₹0. It is shown as unavailable, with
  /// no figure at all.
  final bool priced;

  final int nightCount;

  /// One room of this kind for the whole stay, TAX INCLUDED.
  ///
  /// Tax inclusive because that is the figure a guest recognises and the one
  /// the money display rule insists on — the same headline the web shows.
  final num perUnitGrandTotal;

  /// "Weekly rate" / "Monthly rate" when this stay earns the host's long-stay
  /// price, else null. The host has offered these for months and no guest was
  /// ever told.
  final String? longStayLabel;

  /// A bed list as a sentence: "1 King, 1 Sofa bed".
  String get bedsSentence => beds
      .where((b) => (b['type']?.toString().isNotEmpty ?? false))
      .map((b) => '${b['count']} ${b['type']}')
      .join(', ');

  static int _int(Object? v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  static num _num(Object? v, [num fallback = 0]) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? fallback;
  }

  factory RoomTypeOffer.fromJson(Map<String, dynamic> j) {
    final perUnit = j['perUnit'];
    return RoomTypeOffer(
      roomTypeId: _int(j['roomTypeId']),
      name: j['name']?.toString() ?? 'Room',
      description: j['description']?.toString(),
      beds: (j['beds'] is List)
          ? (j['beds'] as List)
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
          : const [],
      photos: (j['photos'] is List)
          ? (j['photos'] as List)
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      totalGuests: j['totalGuests'] == null ? null : _int(j['totalGuests']),
      guestsIncluded:
          j['guestsIncluded'] == null ? null : _int(j['guestsIncluded']),
      extraGuestPrice: _num(j['extraGuestPrice']),
      quantity: _int(j['quantity']),
      free: _int(j['free']),
      soldOut: j['soldOut'] == true,
      priced: j['priced'] == true,
      nightCount: _int(j['nightCount']),
      perUnitGrandTotal:
          perUnit is Map ? _num(perUnit['grandTotal']) : 0,
      longStayLabel: perUnit is Map
          ? perUnit['longStayLabel']?.toString()
          : null,
    );
  }
}

/// One line of a selection, costed.
class RoomLine {
  const RoomLine({
    required this.roomTypeId,
    required this.name,
    required this.units,
    this.nightCount = 0,
    this.roomSubtotal = 0,
    this.extraGuestFee = 0,
    this.total = 0,
    this.longStayLabel,
  });

  final int roomTypeId;
  final String name;
  final int units;
  final int nightCount;
  final num roomSubtotal;
  final num extraGuestFee;

  /// This line as charged, including its share of the booking's pet fee and
  /// its own tax.
  final num total;
  final String? longStayLabel;

  factory RoomLine.fromJson(Map<String, dynamic> j) => RoomLine(
        roomTypeId: RoomTypeOffer._int(j['roomTypeId']),
        name: j['name']?.toString() ?? 'Room',
        units: RoomTypeOffer._int(j['units'], 1),
        nightCount: RoomTypeOffer._int(j['nightCount']),
        roomSubtotal: RoomTypeOffer._num(j['roomSubtotal']),
        extraGuestFee: RoomTypeOffer._num(j['extraGuestFee']),
        total: RoomTypeOffer._num(j['total']),
        longStayLabel: j['longStayLabel']?.toString(),
      );
}

/// What the guest has chosen, costed — or why it cannot be.
class RoomSelectionQuote {
  const RoomSelectionQuote({
    this.problem,
    this.lines = const [],
    this.roomsTotal = 0,
    this.petFee = 0,
    this.cleaningFee = 0,
    this.tax = 0,
    this.grandTotal = 0,
  });

  /// Why the selection cannot be priced, or null.
  ///
  /// A bad selection is refused WITH A REASON rather than quietly trimmed to
  /// what fits: a guest who asked for three rooms and is charged for two has
  /// been told nothing. Shown verbatim — the server says "Only 2 Deluxe room
  /// left", which tells a guest what to do where "unavailable" does not.
  final String? problem;

  final List<RoomLine> lines;

  /// Pre-tax, rooms only.
  final num roomsTotal;
  final num petFee;

  /// Stated on the listing, arranged with the host. NEVER in the total —
  /// client decision, 2026-09-15.
  final num cleaningFee;

  final num tax;

  /// Tax inclusive. What the guest pays.
  final num grandTotal;

  bool get ok => problem == null && lines.isNotEmpty;

  factory RoomSelectionQuote.fromJson(Map<String, dynamic> j) =>
      RoomSelectionQuote(
        problem: j['problem']?.toString(),
        lines: (j['lines'] is List)
            ? (j['lines'] as List)
                .whereType<Map>()
                .map((e) => RoomLine.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const [],
        roomsTotal: RoomTypeOffer._num(j['roomsTotal']),
        petFee: RoomTypeOffer._num(j['petFee']),
        cleaningFee: RoomTypeOffer._num(j['cleaningFee']),
        tax: RoomTypeOffer._num(j['tax']),
        grandTotal: RoomTypeOffer._num(j['grandTotal']),
      );
}

/// The whole property, at the host's own separate buyout price.
class BuyoutOffer {
  const BuyoutOffer({
    this.enabled = true,
    this.available = true,
    this.reason,
    this.priced = false,
    this.grandTotal,
  });

  final bool enabled;
  final bool available;

  /// Why it is unavailable, in the server's words.
  final String? reason;
  final bool priced;

  /// Tax inclusive. NEVER the sum of the rooms — the host sets this
  /// separately (client decision 1, 2026-10-20), so it can be less than
  /// booking every room.
  final num? grandTotal;

  factory BuyoutOffer.fromJson(Map<String, dynamic> j) => BuyoutOffer(
        enabled: j['enabled'] != false,
        available: j['available'] == true,
        reason: j['reason']?.toString(),
        priced: j['priced'] == true,
        grandTotal:
            j['grandTotal'] == null ? null : RoomTypeOffer._num(j['grandTotal']),
      );
}

/// The answer from POST /pricing/rooms.
class RoomQuote {
  const RoomQuote({
    required this.rentalMode,
    this.rooms = const [],
    this.buyout = const BuyoutOffer(),
    this.petsAllowed = false,
    this.securityDeposit = 0,
    this.depositRefundable = false,
    this.selection,
  });

  /// "by_room", or "whole" — in which case this screen shows nothing and the
  /// page prices the stay the way it always has.
  final String rentalMode;

  final List<RoomTypeOffer> rooms;
  final BuyoutOffer buyout;

  final bool petsAllowed;

  /// Asked for on arrival, never charged through the platform. Stated so a
  /// guest does not first hear of it at the door.
  final num securityDeposit;
  final bool depositRefundable;

  final RoomSelectionQuote? selection;

  bool get byRoom => rentalMode == 'by_room';

  factory RoomQuote.fromJson(Map<String, dynamic> j) => RoomQuote(
        rentalMode: j['rentalMode']?.toString() ?? 'whole',
        rooms: (j['rooms'] is List)
            ? (j['rooms'] as List)
                .whereType<Map>()
                .map((e) => RoomTypeOffer.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const [],
        buyout: j['buyout'] is Map
            ? BuyoutOffer.fromJson((j['buyout'] as Map).cast<String, dynamic>())
            : const BuyoutOffer(),
        petsAllowed: j['petsAllowed'] == true,
        securityDeposit: RoomTypeOffer._num(j['securityDeposit']),
        depositRefundable: j['depositRefundable'] == true,
        selection: j['selection'] is Map
            ? RoomSelectionQuote.fromJson(
                (j['selection'] as Map).cast<String, dynamic>())
            : null,
      );
}

/// What the guest wants, as the server reads it.
class RoomPick {
  const RoomPick({required this.roomTypeId, required this.units});

  final int roomTypeId;
  final int units;

  Map<String, dynamic> toJson() => {
        'roomTypeId': roomTypeId,
        'units': units,
      };
}
