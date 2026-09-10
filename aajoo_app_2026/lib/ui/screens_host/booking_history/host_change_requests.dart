import 'package:flutter/material.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/service/booking_modification_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Change requests waiting on this host.
///
/// Reported 2026-09-10 (bug 28): a guest's request to move their dates was
/// "visible in the booking on the web, but not shown or notified anywhere in
/// the Host app". The app had no idea the feature existed — no model, no
/// service, no screen — so a host who works from their phone could not answer
/// one at all, and the request expired while the nights stayed on sale to
/// everybody else.
///
/// It sits ABOVE the bookings list and renders NOTHING when there is nothing
/// waiting, mirroring the website. A permanent empty panel over the list would
/// train a host to scroll past the one place the urgent thing appears.
///
/// What the host is shown is the DECISION, not the record: the old dates, the
/// new dates, and what it does to the money. Everything else about the booking
/// is one tap away and would only bury those three facts.
class HostChangeRequests extends StatefulWidget {
  const HostChangeRequests({super.key, this.onApplied, this.loader, this.responder});

  /// Called after a request is answered, so the bookings list behind can
  /// reload — an approved change moves the dates on a row already on screen.
  final VoidCallback? onApplied;

  /// Test seams. Default to the real service; a test supplies its own so the
  /// three states — waiting, empty, unreachable — can be driven without a
  /// network. The populated state is the one that matters and is the one a
  /// device cannot show without a pending request on the logged-in host.
  final Future<List<BookingChangeRequest>?> Function()? loader;
  final Future<({bool ok, String message})> Function({
    required int id,
    required bool approve,
    String? note,
  })? responder;

  @override
  State<HostChangeRequests> createState() => _HostChangeRequestsState();
}

class _HostChangeRequestsState extends State<HostChangeRequests> {
  List<BookingChangeRequest>? _rows;
  bool _failed = false;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await (widget.loader ?? BookingModificationService.instance.pending)();
    if (!mounted) return;
    setState(() {
      _rows = r ?? const [];
      // null is "we could not ask", which is not the same as "nothing
      // waiting" — the second is good news and the first is not.
      _failed = r == null;
    });
  }

  Future<void> _respond(BookingChangeRequest row, bool approve) async {
    setState(() => _busyId = row.id);
    final respond = widget.responder ?? BookingModificationService.instance.respond;
    final res = await respond(id: row.id, approve: approve);
    if (!mounted) return;
    setState(() => _busyId = null);

    // The server's own sentence. It knows what this screen does not — that the
    // price moved, that the nights went while the host was deciding.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.message),
      backgroundColor: res.ok ? kIndigo : Colors.red.shade700,
    ));
    await _load();
    if (res.ok) widget.onApplied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    // Say so when the ASK failed. Silence here reads as "nothing waiting",
    // which is the one thing it must not be mistaken for.
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 15, color: kMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text("Couldn't check for change requests.",
                  style: inter(fontSize: 12, color: kMuted)),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (rows == null || rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              const Icon(Icons.edit_calendar_outlined, size: 17, color: kIndigo),
              const SizedBox(width: 7),
              Text(
                rows.length == 1
                    ? '1 change request'
                    : '${rows.length} change requests',
                style: inter(
                    fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk),
              ),
            ],
          ),
        ),
        for (final r in rows) _card(r),
        const Divider(height: 26),
      ],
    );
  }

  Widget _card(BookingChangeRequest r) {
    final busy = _busyId == r.id;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kSand,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking B${r.bookingId}',
              style: inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
          const SizedBox(height: 8),

          // The three facts, in the order a host decides on them.
          if (r.datesChanged)
            _line(Icons.calendar_today_outlined,
                '${r.oldFrom} → ${r.oldTo}', '${r.newFrom} → ${r.newTo}'),
          if (r.guestsChanged)
            _line(Icons.people_outline, '${r.oldGuests} guests',
                '${r.newGuests} guests'),

          const SizedBox(height: 6),
          Text(r.moneyLine,
              style: inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),

          if (r.guestNote != null) ...[
            const SizedBox(height: 8),
            Text('"${r.guestNote}"',
                style: inter(fontSize: 12.5, color: kMuted, height: 1.4)
                    .copyWith(fontStyle: FontStyle.italic)),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : () => _respond(r, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Approve',
                          style: inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _respond(r, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    side: const BorderSide(color: kLine),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Text('Decline',
                      style: inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kInk)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Old value struck through, new value beside it. The change is the point,
  /// so both are shown rather than only what is being asked for.
  Widget _line(IconData icon, String from, String to) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: kMuted),
            const SizedBox(width: 7),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(from,
                      style: inter(fontSize: 12.5, color: kMuted)
                          .copyWith(decoration: TextDecoration.lineThrough)),
                  Text('  →  ', style: inter(fontSize: 12.5, color: kMuted)),
                  Text(to,
                      style: inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kInk)),
                ],
              ),
            ),
          ],
        ),
      );
}
