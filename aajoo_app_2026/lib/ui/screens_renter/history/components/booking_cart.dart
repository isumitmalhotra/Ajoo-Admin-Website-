// The My Bookings card, rebuilt to the reference design.
//
// It used to be a tall text block: a "Booked on:" line at the top, a 22pt
// property name in Flutter's default face, "From: 19-08-2026" / "To: 22-08-2026"
// as raw label-colon-value strings, a grey money strip, and a full-width solid
// teal button. Nothing about it matched the rest of the app, and it took most
// of the screen to say very little.
//
// This is the same information in the shape the client's reference uses: the
// stay's own photo, its status as a pill on the image, the nights as a proper
// date range, guests and total, and an outline "View details". The data behind
// it is unchanged — same fields, same lifecycle/payment split, same detail page
// on tap.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/booking_history_response_model.dart';
import 'package:rent_home/ui/screens_renter/history/history_description/history_description_page.dart';
import 'package:rent_home/utils/fonts.dart';
import '../../../../utils/booking_status.dart';
import '../../../../utils/stay_clock.dart';
import 'package:rent_home/utils/money.dart';

/// A number out of whatever the API sent — 9600, "9600.00", or nothing.
num _asNum(dynamic v) {
  if (v is num) return v;
  return num.tryParse('${v ?? ''}') ?? 0;
}

/// 6300.0 -> "6,300"; keeps paise only when they exist.
/// Digits only; the caller supplies the symbol.
///
/// This grouped every THREE digits — US style — so a stay costing ₹1,04,814
/// rendered as "₹104,814" on the booking card while the same figure read
/// "₹1,04,814" everywhere else in the app. It also printed paise on any amount
/// that was not whole. utils/money.dart does both correctly, once.
String _money(num v) => rupeeDigits(v);

/// "19 Aug" from the DD-MM-YYYY the booking API speaks.
///
/// Falls back to whatever the server sent if it cannot be parsed, rather than
/// printing a dash — a date the guest can read beats a tidy blank.
String _shortDate(String? raw) {
  final parsed = parseStayDate(raw);
  if (parsed == null) return raw ?? '—';
  return DateFormat('d MMM').format(parsed);
}

/// "19 – 22 Aug 2026", collapsing the month and year when both dates share one.
String _stayRange(String? from, String? to) {
  final a = parseStayDate(from);
  final b = parseStayDate(to);
  if (a == null || b == null) return '${_shortDate(from)} – ${_shortDate(to)}';
  final sameMonth = a.year == b.year && a.month == b.month;
  final left = sameMonth
      ? DateFormat('d').format(a)
      : DateFormat(a.year == b.year ? 'd MMM' : 'd MMM yyyy').format(a);
  return '$left – ${DateFormat('d MMM yyyy').format(b)}';
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
  });

  final BookingHistoryData booking;

  int get _nights {
    final a = parseStayDate(booking.bookDetailsBtBookFrom);
    final b = parseStayDate(booking.bookDetailsBtBookTo);
    if (a == null || b == null) return 0;
    return b.difference(a).inDays;
  }

  void _open() => Get.to(
        () => HistoryDescriptionPage(
          bookingData: booking,
          propertyId: booking.bookPropId!,
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Lifecycle and payment are separate questions; see utils/booking_status.
    final life = lifecycleLabel(
      booking.bookingStatusBsTitle,
      ended: hasEnded(booking.bookDetailsBtBookTo),
      started: isStaying(
          booking.bookDetailsBtBookFrom, booking.bookDetailsBtBookTo),
    );
    final pay =
        paymentBadge(isPaid: booking.bookIsPaid, isCod: booking.bookIsCod);
    final lifeColors = lifecycleColors(life);
    final total = (booking.bookTotalAmt ?? 0) > 0
        ? booking.bookTotalAmt!
        // book_price is `dynamic`, and the backend's DECIMAL columns are not
        // consistent about it — property_price arrives as the string
        // "3200.00" while book_price arrives as a number. A blind cast would
        // take the whole card down on the first booking that has no
        // book_total_amt and a stringly-typed price.
        : _asNum(booking.book_price);
    final nights = _nights;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(
                  url: booking.coverImage,
                  status: life,
                  statusBg: lifeColors.$1,
                  statusFg: lifeColors.$2,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.bookingPropertyPropertyName ?? 'Stay',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fraunces(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kInk),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 13, color: kMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              booking.bookingPropertyPropertyAddress ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: inter(fontSize: 12.5, color: kMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dates, nights and guests on one line — the three
                      // things a guest checks before anything else.
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: kIndigo),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _stayRange(booking.bookDetailsBtBookFrom,
                                  booking.bookDetailsBtBookTo),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kInk),
                            ),
                          ),
                          if (nights > 0) ...[
                            Text(
                              '$nights night${nights == 1 ? '' : 's'}',
                              style: inter(fontSize: 12, color: kMuted),
                            ),
                          ],
                        ],
                      ),
                      if ((booking.bookNoOfGuests ?? 0) > 0) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 13, color: kMuted),
                            const SizedBox(width: 5),
                            Text(
                              '${booking.bookNoOfGuests} guest'
                              '${booking.bookNoOfGuests == 1 ? '' : 's'}',
                              style: inter(fontSize: 12.5, color: kMuted),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: kLine),
                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // "Total paid" only when it has been. On a
                                // pay-at-property booking that money has not
                                // moved yet, and the badge beside it says so.
                                // Say that the figure is tax-inclusive. A
                                // list card has no room for a breakdown, but
                                // it can at least stop the reader wondering
                                // whether tax is still to come — the detail
                                // one tap away itemises it.
                                Text(
                                    booking.bookIsPaid
                                        ? 'Total paid · incl. taxes'
                                        : 'Total due · incl. taxes',
                                    style:
                                        inter(fontSize: 11.5, color: kMuted)),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    // The TOTAL the guest owes (room + GST),
                                    // matching the booking detail and the
                                    // confirmation screen. The room subtotal
                                    // alone made one booking show two prices.
                                    Text(
                                      '₹${_money(total)}',
                                      style: fraunces(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: kInk),
                                    ),
                                    const SizedBox(width: 7),
                                    // "Paid" and "Booking Confirmed" were shown
                                    // in the same slot as if they answered the
                                    // same question. One is about the money,
                                    // the other about the stay.
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: pay.bg,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        pay.label,
                                        style: inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: pay.fg),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _open,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kIndigo,
                              side: const BorderSide(color: kIndigo),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('View details',
                                style: inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The stay's photo, with its status sitting on top of it.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.status,
    required this.statusBg,
    required this.statusFg,
  });

  final String? url;
  final String status;
  final Color statusBg;
  final Color statusFg;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      child: Stack(
        children: [
          SizedBox(
            height: 132,
            width: double.infinity,
            child: (url == null || url!.isEmpty)
                ? const _PhotoPlaceholder()
                : Image.network(
                    url!,
                    fit: BoxFit.cover,
                    // A listing whose photo 404s must not leave a grey void
                    // with a broken-image glyph in it.
                    errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const _PhotoPlaceholder(),
                  ),
          ),
          // A scrim under the pill, so a white-walled villa cannot swallow it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 56,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kIndigo50,
      alignment: Alignment.center,
      child: Icon(Icons.villa_outlined, size: 30, color: kIndigo.withOpacity(0.45)),
    );
  }
}
