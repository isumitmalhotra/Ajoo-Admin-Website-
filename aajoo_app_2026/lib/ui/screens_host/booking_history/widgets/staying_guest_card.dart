import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/traveller_model.dart';
import 'package:rent_home/service/traveller_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Who is actually staying, when it is not the person who paid.
///
/// A host preparing for an arrival — and required to keep a guest register —
/// previously had only the payer's name to work from. Renders nothing at all
/// when the account holder is the guest, which is most bookings: an absent
/// card is the right answer there, not an empty one.
///
/// The ID opens through a link the server signs on request and which expires
/// in minutes, so nothing here is cached. A link held on the page would
/// quietly stop working, and one that did not expire is exactly the thing
/// being avoided.
class StayingGuestCard extends StatefulWidget {
  /// Either the numeric booking id or the "B…" reference — the API takes both.
  final dynamic bookingId;

  const StayingGuestCard({super.key, required this.bookingId});

  @override
  State<StayingGuestCard> createState() => _StayingGuestCardState();
}

class _StayingGuestCardState extends State<StayingGuestCard> {
  final _service = TravellerService();
  Traveller? _traveller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await _service.forBooking(widget.bookingId);
    if (mounted) setState(() => _traveller = t);
  }

  Future<void> _openId() async {
    final t = _traveller;
    if (t == null) return;
    setState(() => _busy = true);
    final url = await _service.documentUrl(t.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That document isn't available.")),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _traveller;
    if (t == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STAYING GUEST',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: .5,
                  fontWeight: FontWeight.w700,
                  color: kMuted)),
          const SizedBox(height: 6),
          Text(t.fullName,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 2),
          Text(t.summary, style: TextStyle(fontSize: 12, color: kMuted)),
          if (t.email != null)
            Text(t.email!, style: TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 10),
          if (t.hasDocument)
            OutlinedButton.icon(
              onPressed: _busy ? null : _openId,
              icon: const Icon(Icons.badge_outlined, size: 17),
              label: Text(_busy ? 'Opening…' : 'View ${t.docType ?? "ID"}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo,
                side: const BorderSide(color: kIndigo),
              ),
            )
          else
            Text('No ID on file',
                style: TextStyle(fontSize: 12, color: kMuted, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
