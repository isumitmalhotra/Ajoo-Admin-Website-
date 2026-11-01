// The room table of a by-room property, and what the guest's picks come to.
//
// Room-level booking, phase 2 — the app's half. The web carries the same
// screen in redesign/components/RoomTypeTable.tsx, and the two must agree.
//
// ── THIS WIDGET ADDS UP NOTHING ─────────────────────────────────────────────
//
// Every figure comes from POST /pricing/rooms. Not one multiplication happens
// here — not even "units x per-room price", which looks harmless and is not:
// GST on accommodation is banded per room per night, so two ₹2,400 rooms are
// two 5% supplies while their ₹9,600 sum would look like an 18% one. This app
// already carries utils/gst.dart because a client that reinvents the slab rule
// gets it wrong, and booking_pricing.dart records what it cost last time — a
// guest quoted ₹23,020 and charged ₹24,171.
//
// So the stepper changes the picks, the picks are sent, and the footer renders
// whatever came back. While a reply is in flight the previous total stays on
// screen dimmed rather than vanishing: a total that disappears on every tap
// reads as a broken screen.
//
// ── Renders nothing for a whole-let property ────────────────────────────────
//
// Which is almost the entire catalogue. The property page mounts this
// unconditionally and it disappears unless the server says by_room.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/models/room_quote_model.dart';
import 'package:rent_home/service/booking_service.dart';
import 'package:rent_home/utils/cloudinary_url.dart';
import 'package:rent_home/utils/money.dart';

/// What the property page needs back when the guest has chosen.
class RoomChoice {
  const RoomChoice({
    required this.picks,
    required this.byRoom,
    this.grandTotal,
    this.problem,
  });

  final List<RoomPick> picks;

  /// True once the server has said this property sells rooms.
  final bool byRoom;

  /// Tax inclusive, straight from the server. Null until a selection prices.
  final num? grandTotal;

  /// Why the selection cannot be booked, in the server's own words.
  final String? problem;
}

class RoomTypeTable extends StatefulWidget {
  const RoomTypeTable({
    super.key,
    required this.propertyId,
    required this.bookFrom,
    required this.bookTo,
    this.pets = 0,
    this.onChanged,
  });

  final int propertyId;

  /// DD-MM-YYYY, as every other call in this app sends dates. Null before the
  /// guest has picked their nights, and the table does not appear until then —
  /// the prices depend on them.
  final String? bookFrom;
  final String? bookTo;

  final int pets;
  final ValueChanged<RoomChoice>? onChanged;

  @override
  State<RoomTypeTable> createState() => _RoomTypeTableState();
}

class _RoomTypeTableState extends State<RoomTypeTable> {
  final BookingService _svc = BookingService();

  RoomQuote? _quote;

  /// Units the guest wants, by room type id. Absent means none.
  final Map<int, int> _picked = {};

  bool _loading = false;

  /// Set when the call FAILED, as opposed to not having landed yet.
  ///
  /// The two must look different: "we couldn't check the rooms" is not "there
  /// are no rooms", and showing an empty table for a failure loses a booking.
  bool _failed = false;

  Timer? _debounce;
  CancelToken? _inFlight;

  List<RoomPick> get _picks => _picked.entries
      .where((e) => e.value > 0)
      .map((e) => RoomPick(roomTypeId: e.key, units: e.value))
      .toList();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant RoomTypeTable old) {
    super.didUpdateWidget(old);
    if (old.bookFrom != widget.bookFrom ||
        old.bookTo != widget.bookTo ||
        old.pets != widget.pets ||
        old.propertyId != widget.propertyId) {
      // New dates are a new question. Clearing the picks is deliberate: a
      // selection made against one set of nights says nothing about another,
      // and carrying it over would quietly re-price rooms the guest chose for
      // a different stay.
      _picked.clear();
      _fetch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inFlight?.cancel();
    super.dispose();
  }

  void _fetch() {
    final from = widget.bookFrom;
    final to = widget.bookTo;
    if (from == null || to == null || from.isEmpty || to.isEmpty) {
      setState(() {
        _quote = null;
        _failed = false;
      });
      return;
    }

    // Debounced and CANCELLED on change, so a slow reply cannot overwrite a
    // newer one — the same discipline the web client uses.
    _debounce?.cancel();
    _inFlight?.cancel();
    setState(() => _loading = true);

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final token = CancelToken();
      _inFlight = token;
      final picks = _picks;
      final q = await _svc.getRoomQuote(
        propertyId: widget.propertyId,
        bookFrom: from,
        bookTo: to,
        picks: picks.isEmpty ? null : picks,
        pets: widget.pets,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;
      setState(() {
        _loading = false;
        _failed = q == null;
        if (q != null) _quote = q;
      });
      _report();
    });
  }

  /// Tell the page what was chosen — from the SERVER's answer, never from the
  /// tap. Reporting on the tap would hand the page a total before one existed.
  void _report() {
    final sel = _quote?.selection;
    final priced = sel != null && sel.problem == null ? sel : null;
    widget.onChanged?.call(RoomChoice(
      picks: _picks,
      byRoom: _quote?.byRoom ?? false,
      grandTotal: priced?.grandTotal,
      problem: sel?.problem,
    ));
  }

  void _setUnits(int roomTypeId, int units) {
    setState(() {
      if (units <= 0) {
        _picked.remove(roomTypeId);
      } else {
        _picked[roomTypeId] = units;
      }
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookFrom == null || widget.bookTo == null) {
      return const SizedBox.shrink();
    }

    if (_failed && _quote == null) {
      return Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          border: Border.all(color: const Color(0xFFFFEEBA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF856404), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "We couldn't check the rooms just now. Please try again in a moment.",
                style: TextStyle(color: Color(0xFF856404), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final quote = _quote;
    if (quote == null || !quote.byRoom) return const SizedBox.shrink();

    final chosen = _picks.fold<int>(0, (a, p) => a + p.units);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Choose your rooms',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'prices include taxes',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...quote.rooms.map((r) => _RoomRow(
              room: r,
              units: _picked[r.roomTypeId] ?? 0,
              onUnits: (n) => _setUnits(r.roomTypeId, n),
            )),
        if (quote.buyout.enabled && quote.buyout.priced)
          _BuyoutRow(buyout: quote.buyout),
        if (chosen > 0) _Footer(quote: quote, dimmed: _loading),
      ],
    );
  }
}

/* ── One room type ───────────────────────────────────────────────────────── */

class _RoomRow extends StatelessWidget {
  const _RoomRow({
    required this.room,
    required this.units,
    required this.onUnits,
  });

  final RoomTypeOffer room;
  final int units;
  final ValueChanged<int> onUnits;

  @override
  Widget build(BuildContext context) {
    // A room with no price for these dates is NOT free and not sold out: the
    // host simply has no rate for them. Shown greyed with no figure, because
    // inventing a ₹0 is the one unforgivable answer.
    final bookable = room.priced && room.free > 0;
    final detail = [
      if (room.totalGuests != null) 'Sleeps ${room.totalGuests}',
      if (room.bedsSentence.isNotEmpty) room.bedsSentence,
    ].join(' · ');

    return Opacity(
      opacity: bookable ? 1 : 0.62,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.photos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  // f_auto, or Flutter cannot decode what Cloudinary serves —
                  // an AVIF comes back as a broken image on BOTH platforms
                  // while the website looks fine.
                  // Falls back to the raw url rather than `!`: the helper
                  // returns null only for a null or empty input, which the
                  // model already filters out, and a bang here would turn a
                  // future change in that filter into a crash on a photograph.
                  deliverableImageUrl(room.photos.first) ?? room.photos.first,
                  width: 84,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 84,
                    height: 64,
                    child: Icon(Icons.bed_outlined, color: Colors.grey),
                  ),
                ),
              ),
            if (room.photos.isNotEmpty) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (detail.isNotEmpty)
                    Text(detail,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if ((room.description ?? '').isNotEmpty)
                    Text(
                      room.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    // A COUNT, not a yes/no. "Only 1 left" is the whole reason
                    // this feature exists, and it is what makes a guest decide.
                    !room.priced
                        ? 'No price for these dates'
                        : room.free <= 0
                            ? 'Fully booked for these dates'
                            : room.free == 1
                                ? 'Only 1 left'
                                : '${room.free} of ${room.quantity} left',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: room.free > 0 && room.priced
                          ? const Color(0xFF047857)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (room.priced) ...[
                  Text(
                    // Tax inclusive, always — the figure a guest recognises.
                    rupees(room.perUnitGrandTotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(
                    'per room · ${room.nightCount} night${room.nightCount == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (room.longStayLabel != null)
                    Text(
                      '${room.longStayLabel} applied',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF047857)),
                    ),
                ] else
                  Text('—', style: TextStyle(color: Colors.grey[600])),
                if (bookable) ...[
                  const SizedBox(height: 6),
                  _Stepper(
                    value: units,
                    // Capped at what is actually free. The server refuses more
                    // and says so, but a stepper that lets a guest climb to
                    // six and then tells them off is a worse way to learn
                    // there are two.
                    max: room.free,
                    onChanged: onUnits,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ── The quantity stepper ────────────────────────────────────────────────── */

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, VoidCallback tap, String label) =>
        Semantics(
          button: true,
          label: label,
          child: InkWell(
            onTap: enabled ? tap : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 16,
                  color: enabled ? Colors.black87 : Colors.grey.shade400),
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove, value > 0, () => onChanged(value - 1), 'One fewer'),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        btn(Icons.add, value < max, () => onChanged(value + 1), 'One more'),
      ],
    );
  }
}

/* ── The whole property ──────────────────────────────────────────────────── */

class _BuyoutRow extends StatelessWidget {
  const _BuyoutRow({required this.buyout});

  final BuyoutOffer buyout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Or take the whole property',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  // The host's own buyout price — deliberately NOT the sum of
                  // the rooms, which is why it can be less than booking them all.
                  buyout.available
                      ? 'Every room, for your dates'
                      : (buyout.reason ?? 'Not available for these dates'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            rupees(buyout.grandTotal ?? 0),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/* ── What the picks come to ──────────────────────────────────────────────── */

class _Footer extends StatelessWidget {
  const _Footer({required this.quote, required this.dimmed});

  final RoomQuote quote;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final sel = quote.selection;

    Widget row(String label, String? detail, num amount) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    children: [
                      TextSpan(text: label),
                      if (detail != null)
                        TextSpan(
                          text: ' · $detail',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ),
              Text(rupeesExact(amount),
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
        );

    return AnimatedOpacity(
      opacity: dimmed ? 0.6 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: sel == null
            ? Text('Working out your total…',
                style: TextStyle(color: Colors.grey[600], fontSize: 13))
            : sel.problem != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      // The server's own words. A client that rewrites them
                      // ends up saying "unavailable" where the server said
                      // "only 2 left".
                      Expanded(
                        child: Text(sel.problem!,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFB45309))),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...sel.lines.map((l) => row(
                            '${l.name} x ${l.units}',
                            [
                              '${l.nightCount} night${l.nightCount == 1 ? '' : 's'}',
                              if (l.longStayLabel != null) l.longStayLabel!,
                            ].join(' · '),
                            l.roomSubtotal,
                          )),
                      if (sel.lines.any((l) => l.extraGuestFee > 0))
                        row(
                            'Extra guests',
                            null,
                            sel.lines.fold<num>(
                                0, (a, l) => a + l.extraGuestFee)),
                      if (sel.petFee > 0)
                        row('Pet fee', 'For the whole stay', sel.petFee),
                      row('Taxes & GST', null, sel.tax),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                          Text(rupeesExact(sel.grandTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                      // Stated, never charged — client decision, 2026-09-15.
                      // Below the total so it cannot read as part of it.
                      if (sel.cleaningFee > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'The host charges ${rupees(sel.cleaningFee)} for cleaning, '
                            'arranged and paid with them directly. Not included above.',
                            style: TextStyle(
                                fontSize: 11.5, color: Colors.grey[600]),
                          ),
                        ),
                      if (quote.securityDeposit > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'A deposit of ${rupees(quote.securityDeposit)} is asked for on '
                            'arrival${quote.depositRefundable ? ' and returned when you leave' : ''}. '
                            'Not included above.',
                            style: TextStyle(
                                fontSize: 11.5, color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
