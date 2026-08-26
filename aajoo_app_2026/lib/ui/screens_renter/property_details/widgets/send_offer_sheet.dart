import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/service/deals_service.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';

/// "Send an Offer" — the app's twin of the website's negotiation modal.
///
/// WHY THIS REPLACED THE CHAT SCREEN
///
/// The app negotiated over a socket: tapping Negotiate opened a live chat with
/// a thirty-second "Waiting for host response" countdown, six quick-price
/// chips (−₹200 … +₹200), a running offer counter and a message box. The
/// website asks three questions in one modal — your price, your dates, an
/// optional message — and then gets out of the way.
///
/// Two clients negotiating through two different transports against one engine
/// is how they came to disagree: the countdown implied a host was sitting at
/// their phone about to answer within thirty seconds, which is not how the
/// server works at all. It escalates to the host, notifies them, and waits.
///
/// So this asks the same three questions the web asks, posts the same REST
/// offer, and reports the same two outcomes:
///
///   * accepted outright — the offer cleared the host's floor, the server has
///     already minted the 24-hour coupon, and the guest is told to book;
///   * sent to the host — they will answer, and the guest is notified.
///
/// Deliberately NOT a chat. An ongoing thread is still readable from the
/// negotiations list; this is the opening move, and on a phone it should cost
/// one screen, not a room.
class SendOfferSheet extends StatefulWidget {
  const SendOfferSheet({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.nightlyPrice,
    this.initialFrom,
    this.initialTo,
    this.onAccepted,
  });

  final int propertyId;
  final String propertyName;

  /// The listed nightly rate, shown as the thing being negotiated against.
  final double nightlyPrice;

  /// Dates already chosen on the property page, so the guest is not asked
  /// twice for something they have said.
  final DateTime? initialFrom;
  final DateTime? initialTo;

  /// Fired when the offer was accepted outright, so the caller can refresh the
  /// price and let the guest book at it.
  final VoidCallback? onAccepted;

  @override
  State<SendOfferSheet> createState() => _SendOfferSheetState();
}

class _SendOfferSheetState extends State<SendOfferSheet> {
  final _price = TextEditingController();
  final _message = TextEditingController();

  DateTime? _from;
  DateTime? _to;
  bool _busy = false;
  String? _error;
  OfferOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  @override
  void dispose() {
    _price.dispose();
    _message.dispose();
    super.dispose();
  }

  /// The API takes DD-MM-YYYY, like every other date on this platform.
  static String? _api(DateTime? d) => d == null
      ? null
      : '${d.day.toString().padLeft(2, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-${d.year}';

  static String _pretty(DateTime d) => DateFormat('d MMM').format(d);

  int get _nights =>
      (_from == null || _to == null) ? 0 : _to!.difference(_from!).inDays;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: (_from != null && _to != null && _to!.isAfter(_from!))
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kIndigo),
        ),
        child: child!,
      ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _from = range.start;
      _to = range.end;
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_price.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter the price you would like to pay per night.');
      return;
    }
    // A guest offering MORE than the listing is almost always a typo, and the
    // host has no reason to refuse it — so it is worth a word rather than a
    // silent send.
    if (amount >= widget.nightlyPrice) {
      setState(() => _error =
          'That is at or above the listed ${rupees(widget.nightlyPrice)}. '
          'Offer less than the asking price to negotiate.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final outcome = await DealsService().sendOffer(
      propertyId: widget.propertyId,
      offerPrice: amount,
      message: _message.text,
      bookFrom: _api(_from),
      bookTo: _api(_to),
    );

    if (!mounted) return;
    if (outcome.failed) {
      setState(() {
        _busy = false;
        _error = outcome.error;
      });
      return;
    }
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
    if (outcome.accepted) widget.onAccepted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LuxBuilder(
      builder: (context, skin) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: skin.sheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: skin.line,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Send an Offer',
                            style: fraunces(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: skin.ink)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: skin.ink),
                      ),
                    ],
                  ),
                  if (_outcome == null) ...[
                    Text(
                      'Propose your price to the host. They can accept, '
                      'reject or counter.',
                      style: inter(fontSize: 13, color: skin.muted, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    _form(skin),
                  ] else
                    _result(skin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AajooSkin skin) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(skin, 'Your offer per night (₹)'),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            style: inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: skin.ink),
            decoration: _input(skin, widget.nightlyPrice.toStringAsFixed(0)),
          ),
          const SizedBox(height: 4),
          Text('Listed at ${rupees(widget.nightlyPrice)} / night',
              style: inter(fontSize: 11.5, color: skin.muted)),
          const SizedBox(height: 16),

          _label(skin, "Dates you'd like to stay"),
          InkWell(
            onTap: _pickDates,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: skin.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: _dateCell(skin, 'CHECK-IN', _from)),
                  Container(width: 1, height: 46, color: skin.line),
                  Expanded(child: _dateCell(skin, 'CHECK-OUT', _to)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _nights > 0
                ? 'Your deal, if accepted, will be locked to these '
                    '$_nights night${_nights == 1 ? '' : 's'}.'
                : 'The host sanctions these dates along with the price.',
            style: inter(fontSize: 11.5, color: skin.muted),
          ),
          const SizedBox(height: 16),

          _label(skin, 'Message to host (optional)'),
          TextField(
            controller: _message,
            maxLines: 3,
            maxLength: 500,
            style: inter(fontSize: 14, color: skin.ink),
            decoration: _input(
              skin,
              'Loved the place — would you consider this for a '
              '3-night stay?',
            ).copyWith(counterText: ''),
          ),

          if (_error != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kDangerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!,
                  style: inter(fontSize: 12.5, color: kDanger, height: 1.35)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: skin.primary,
                foregroundColor: skin.onPrimary,
                disabledBackgroundColor: skin.line,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Send Offer',
                      style: inter(
                          fontSize: 15.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );

  /// Two answers, and only two — the same pair the website reports.
  Widget _result(AajooSkin skin) {
    final o = _outcome!;
    final accepted = o.accepted;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accepted ? kSuccessBg : skin.primaryWash,
            ),
            child: Icon(accepted ? Icons.check_rounded : Icons.schedule_rounded,
                size: 26, color: accepted ? kSuccess : skin.primary),
          ),
          const SizedBox(height: 12),
          Text(
            accepted
                ? 'Accepted${o.price != null ? ' at ${rupees(o.price!)}/night' : ''}'
                : 'Offer sent to the host',
            textAlign: TextAlign.center,
            style: fraunces(
                fontSize: 17, fontWeight: FontWeight.w700, color: skin.ink),
          ),
          const SizedBox(height: 6),
          Text(
            accepted
                ? 'Your price is locked in. It applies automatically at '
                    'checkout — book within 24 hours to keep it.'
                : "They can accept, decline or counter — you'll be notified "
                    'either way.',
            textAlign: TextAlign.center,
            style: inter(fontSize: 13, color: skin.muted, height: 1.45),
          ),
          if (accepted && (o.couponCode ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: skin.isLux ? skin.surface : kCream,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: skin.line, style: BorderStyle.solid, width: 1),
              ),
              child: Text(
                o.couponCode!,
                textAlign: TextAlign.center,
                style: inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: skin.ink),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(accepted),
              style: ElevatedButton.styleFrom(
                backgroundColor: accepted ? kClay : skin.primary,
                foregroundColor: accepted ? kAccentInk : skin.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(accepted ? 'Book at this price' : 'Done',
                  style: inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(AajooSkin skin, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: skin.ink)),
      );

  Widget _dateCell(AajooSkin skin, String label, DateTime? value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                    color: skin.muted)),
            const SizedBox(height: 2),
            Text(value == null ? 'Add date' : _pretty(value),
                style: inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: value == null ? skin.muted : skin.ink)),
          ],
        ),
      );

  InputDecoration _input(AajooSkin skin, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: inter(fontSize: 14, color: skin.placeholder),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: skin.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: skin.primary, width: 1.5),
        ),
      );
}

/// Open the sheet. Returns true when the offer was accepted outright.
Future<bool> showSendOfferSheet(
  BuildContext context, {
  required int propertyId,
  required String propertyName,
  required double nightlyPrice,
  DateTime? initialFrom,
  DateTime? initialTo,
  VoidCallback? onAccepted,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SendOfferSheet(
      propertyId: propertyId,
      propertyName: propertyName,
      nightlyPrice: nightlyPrice,
      initialFrom: initialFrom,
      initialTo: initialTo,
      onAccepted: onAccepted,
    ),
  );
  return result == true;
}
