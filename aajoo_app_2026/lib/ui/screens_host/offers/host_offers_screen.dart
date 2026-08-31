import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart' as host_props;
import 'package:rent_home/service/host_offers_service.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';

/// Offers — running a limited-time discount on your own listing.
///
/// The mobile counterpart of the web's /host/offers. The guest side of this
/// already worked on the phone: a discounted listing shows the old price struck
/// through and the new one beside it, on the search card, the property page and
/// at checkout. Only the control was missing — a host could watch a discount
/// run on their listing and had no way to start, change or stop one without
/// opening a laptop.
///
/// This is NOT a coupon. Nobody types a code; the listing simply shows a lower
/// price and returns to normal when the window closes or the bookings run out.
///
/// The form's real job is making three consequences impossible to miss, because
/// each one surprises a host who did not read them — the same three the website
/// spells out:
///
///   1. A discounted listing is NOT negotiable while the offer runs.
///   2. It is paid in full unless the host ticks the other boxes.
///   3. The buffer means a few more than the cap may get the price.
class HostOffersScreen extends StatefulWidget {
  const HostOffersScreen({super.key});

  @override
  State<HostOffersScreen> createState() => _HostOffersScreenState();
}

class _HostOffersScreenState extends State<HostOffersScreen> {
  final _service = HostOffersService.instance;
  final _hostService = HostService();

  List<HostOffer> _offers = const [];
  bool _loading = true;

  /// A failed request must not render as "no offers running" — the reassuring
  /// wrong answer. Same rule as the settlements screen.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _service.list();
      if (!mounted) return;
      setState(() {
        _offers = rows;
        _failed = false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _offers = const [];
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _end(HostOffer o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('End this offer?',
            style: fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
        content: Text(
          '${o.property} goes back to ${rupees(o.was)} a night straight away. '
          'Bookings already made at the offer price are not affected.',
          style: inter(fontSize: 13.5, color: kInk2, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Keep it running', style: inter(color: kMuted))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('End offer',
                  style: inter(color: Colors.red.shade700, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok != true) return;

    final err = await _service.end(o.id);
    if (!mounted) return;
    if (err != null) {
      Get.snackbar('Not ended', err,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      return;
    }
    Get.snackbar('Offer ended', 'Your listing is back to its normal price.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kSuccess,
        colorText: Colors.white);
    _load();
  }

  Future<void> _openForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewOfferSheet(hostService: _hostService, service: _service),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final running = _offers.where((o) => o.isRunning).toList();

    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: kSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kInk,
        titleSpacing: 0,
        title: Text('Offers',
            style: fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: kClay,
        foregroundColor: kAccentInk,
        icon: const Icon(Icons.local_offer_outlined, size: 18),
        label: Text('Start an offer',
            style: inter(fontWeight: FontWeight.w600, fontSize: 13.5)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                children: [
                  Text(
                    'A limited-time discount shown on your listing — no code for '
                    'the guest to type.',
                    style: inter(fontSize: 13, color: kMuted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  if (_failed)
                    _errorCard()
                  else if (_offers.isEmpty)
                    _emptyCard()
                  else ...[
                    Text(
                      running.isEmpty
                          ? 'Nothing running right now.'
                          : '${running.length} offer${running.length == 1 ? '' : 's'} running now',
                      style: inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: kInk),
                    ),
                    const SizedBox(height: 10),
                    for (final o in _offers) ...[
                      _offerCard(o),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _errorCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: Colors.red.shade700, width: 3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't load your offers. This is a failed request, not an "
                'empty list — pull down to try again.',
                style: inter(fontSize: 12.5, color: Colors.red.shade700, height: 1.5),
              ),
            ),
          ],
        ),
      );

  Widget _emptyCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kLine),
        ),
        child: Column(
          children: [
            const Icon(Icons.local_offer_outlined, size: 30, color: kClay),
            const SizedBox(height: 10),
            Text('No offers yet',
                style: fraunces(
                    fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            Text(
              'Run a discount for a few days to get a quiet listing seen. '
              'The old price stays visible, struck through.',
              textAlign: TextAlign.center,
              style: inter(fontSize: 12.5, color: kMuted, height: 1.5),
            ),
          ],
        ),
      );

  Widget _offerCard(HostOffer o) {
    final tone = o.isRunning ? kSuccess : kMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(o.property,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tone.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(o.status,
                    style: inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: tone)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rupees(o.now),
                  style: fraunces(
                      fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(width: 8),
              Text(rupees(o.was),
                  style: inter(fontSize: 13, color: kMuted).copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: kMuted)),
              const Spacer(),
              if (o.percent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${o.percent.round()}% off',
                      style: inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(o.title, style: inter(fontSize: 12.5, color: kInk2)),
          const SizedBox(height: 6),
          Text(
            [
              'Ends ${_fmtDate(o.endsAt)}',
              if (o.slotLimit != null)
                '${o.slotsUsed} of ${o.slotLimit} taken'
              else
                '${o.slotsUsed} taken',
            ].join(' · '),
            style: inter(fontSize: 11.5, color: kMuted),
          ),
          if (o.startedByAdmin) ...[
            const SizedBox(height: 8),
            Text('Run by Aajoo on your listing — contact support to change it.',
                style: inter(fontSize: 11.5, color: kMuted, height: 1.4)),
          ],
          if (o.endedReason != null && o.endedReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(o.endedReason!, style: inter(fontSize: 11.5, color: kMuted)),
          ],
          // Only a running offer a host started themselves can be stopped here.
          // An admin campaign on your listing is not yours to end.
          if (o.isRunning && !o.startedByAdmin) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => _end(o),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('End offer',
                    style: inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  return DateFormat('d MMM yyyy').format(d.toLocal());
}

// ───────────────────────────────────────────────────────────────────────────
// The form
// ───────────────────────────────────────────────────────────────────────────

class _NewOfferSheet extends StatefulWidget {
  const _NewOfferSheet({required this.hostService, required this.service});

  final HostService hostService;
  final HostOffersService service;

  @override
  State<_NewOfferSheet> createState() => _NewOfferSheetState();
}

class _NewOfferSheetState extends State<_NewOfferSheet> {
  final _titleCtrl = TextEditingController(text: 'Limited time offer');
  final _percentCtrl = TextEditingController(text: '10');
  final _priceCtrl = TextEditingController();
  final _slotCtrl = TextEditingController();
  final _bufferCtrl = TextEditingController(text: '3');

  List<_Pick> _props = const [];

  /// How many listings were left out for having no price at all — a listing
  /// with none cannot carry a discount and the server refuses it, so offering
  /// it here would be a dead end found only after filling the form in.
  int _hiddenNoPrice = 0;

  int? _propertyId;
  String _kind = 'percent';
  DateTime _endsAt = DateTime.now().add(const Duration(days: 7));
  bool _allowDeposit = false;
  bool _allowCod = false;
  bool _saving = false;
  bool _loadingProps = true;

  @override
  void initState() {
    super.initState();
    _loadProps();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _percentCtrl.dispose();
    _priceCtrl.dispose();
    _slotCtrl.dispose();
    _bufferCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProps() async {
    try {
      // One page, not the account: a host may own tens of thousands.
      final res = await widget.hostService.getHostProperties(limit: 100);
      final all = (res.data?.properties ?? const <host_props.Property>[])
          .map((p) => _Pick(
                id: p.propertyId,
                name: p.propertyName,
                price: num.tryParse(p.propertyPrice) ?? 0,
              ))
          .where((p) => p.id != 0)
          .toList();
      if (!mounted) return;
      setState(() {
        _props = all.where((p) => p.price > 0).toList();
        _hiddenNoPrice = all.length - _props.length;
        _loadingProps = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProps = false);
    }
  }

  _Pick? get _chosen {
    for (final p in _props) {
      if (p.id == _propertyId) return p;
    }
    return null;
  }

  /// Previewed with the same arithmetic the server uses, so the host is never
  /// shown one number and charged another.
  num get _preview {
    final c = _chosen;
    if (c == null) return 0;
    if (_kind == 'percent') {
      final pct = num.tryParse(_percentCtrl.text.trim()) ?? 0;
      return (c.price * (100 - pct) / 100).round();
    }
    return num.tryParse(_priceCtrl.text.trim())?.round() ?? 0;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    setState(() => _endsAt = DateTime(d.year, d.month, d.day, 23, 59));
  }

  Future<void> _submit() async {
    if (_propertyId == null) {
      Get.snackbar('Choose a listing', 'Pick which listing this offer is for.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _saving = true);

    final slotText = _slotCtrl.text.trim();
    final err = await widget.service.create(NewHostOffer(
      propertyId: _propertyId!,
      kind: _kind,
      percent: num.tryParse(_percentCtrl.text.trim()),
      price: num.tryParse(_priceCtrl.text.trim()),
      title: _titleCtrl.text.trim().isEmpty
          ? 'Limited time offer'
          : _titleCtrl.text.trim(),
      endsAt: _endsAt,
      slotLimit: slotText.isEmpty ? null : int.tryParse(slotText),
      buffer: int.tryParse(_bufferCtrl.text.trim()) ?? 0,
      allowDeposit: _allowDeposit,
      allowCod: _allowCod,
    ));

    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      // The server owns every rule — the floor, the window, the percentage
      // ceiling — so its sentence is the one worth showing.
      Get.snackbar('Not started', err,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white);
      return;
    }
    Navigator.pop(context, true);
    Get.snackbar('Your offer is live', 'Guests will see the new price now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kSuccess,
        colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final c = _chosen;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: kSand,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: kLine, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Text('New offer',
                style: fraunces(
                    fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 16),

            // ── which listing ──────────────────────────────────────────────
            _label('Listing'),
            if (_loadingProps)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kLine),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _propertyId,
                    hint: Text('Choose a listing',
                        style: inter(fontSize: 13.5, color: kMuted)),
                    items: [
                      for (final p in _props)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} · ${rupees(p.price)}',
                              overflow: TextOverflow.ellipsis,
                              style: inter(fontSize: 13.5, color: kInk)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _propertyId = v),
                  ),
                ),
              ),
            if (_hiddenNoPrice > 0) ...[
              const SizedBox(height: 6),
              Text(
                '$_hiddenNoPrice listing${_hiddenNoPrice == 1 ? '' : 's'} '
                'not shown — a listing with no nightly price cannot carry a '
                'discount.',
                style: inter(fontSize: 11.5, color: kMuted, height: 1.4),
              ),
            ],
            const SizedBox(height: 14),

            // ── how much ───────────────────────────────────────────────────
            _label('Discount'),
            Row(
              children: [
                Expanded(
                  child: _segment('A percentage', 'percent'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _segment('A set price', 'price'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_kind == 'percent')
              _input(_percentCtrl, 'Percent off', suffix: '%', digits: true)
            else
              _input(_priceCtrl, 'New nightly price', prefix: '₹', digits: true),
            if (c != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kLine),
                ),
                child: Row(
                  children: [
                    Text('Guests will see ',
                        style: inter(fontSize: 12.5, color: kInk2)),
                    Text(rupees(c.price),
                        style: inter(fontSize: 12.5, color: kMuted).copyWith(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: kMuted)),
                    const SizedBox(width: 6),
                    Text(rupees(_preview),
                        style: inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            _label('Name this offer'),
            _input(_titleCtrl, 'Shown on the listing'),
            const SizedBox(height: 14),

            _label('Runs until'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kLine),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: kMuted),
                    const SizedBox(width: 10),
                    Text(DateFormat('d MMM yyyy').format(_endsAt),
                        style: inter(fontSize: 13.5, color: kInk)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            _label('Limit the number of bookings (optional)'),
            _input(_slotCtrl, 'Leave blank for unlimited', digits: true),
            const SizedBox(height: 12),
            _label('Buffer'),
            _input(_bufferCtrl, 'Extra bookings past the limit', digits: true),
            const SizedBox(height: 6),
            Text(
              'A guest already on the payment screen when the last slot goes '
              'should not have the price change under them. The buffer is how '
              'many past the limit still get the offer price — so a few more '
              'than your cap may take it.',
              style: inter(fontSize: 11.5, color: kMuted, height: 1.5),
            ),
            const SizedBox(height: 16),

            // ── the three consequences ─────────────────────────────────────
            _consequences(),
            const SizedBox(height: 12),

            CheckboxListTile(
              value: _allowDeposit,
              onChanged: (v) => setState(() => _allowDeposit = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: kIndigo,
              dense: true,
              title: Text('Allow paying 10% now, the rest before check-in',
                  style: inter(fontSize: 13, color: kInk)),
            ),
            CheckboxListTile(
              value: _allowCod,
              onChanged: (v) => setState(() => _allowCod = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: kIndigo,
              dense: true,
              title: Text('Allow paying at the property',
                  style: inter(fontSize: 13, color: kInk)),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kClay,
                  foregroundColor: kAccentInk,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Start this offer',
                        style: inter(
                            fontSize: 14.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _consequences() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Before you start it',
                style: inter(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 8),
            _bullet('Guests cannot negotiate on this listing while the offer '
                'runs, and platform coupons will not apply on top of it.'),
            _bullet('It is paid in full unless you tick one of the boxes '
                'below.'),
            _bullet('Starting an offer replaces any offer already running on '
                'the same listing.'),
          ],
        ),
      );

  Widget _bullet(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('· ', style: inter(fontSize: 12.5, color: kMuted)),
            Expanded(
              child: Text(s,
                  style: inter(fontSize: 12, color: kInk2, height: 1.5)),
            ),
          ],
        ),
      );

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(s,
            style: inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
      );

  Widget _segment(String label, String value) {
    final on = _kind == value;
    return InkWell(
      onTap: () => setState(() => _kind = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? kIndigo.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? kIndigo : kLine),
        ),
        child: Text(label,
            style: inter(
                fontSize: 13,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? kIndigo : kInk2)),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String hint, {
    String? prefix,
    String? suffix,
    bool digits = false,
  }) =>
      TextField(
        controller: c,
        keyboardType: digits ? TextInputType.number : TextInputType.text,
        inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        onChanged: (_) => setState(() {}),
        style: inter(fontSize: 13.5, color: kInk),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: inter(fontSize: 13, color: kMuted),
          prefixText: prefix,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kIndigo),
          ),
        ),
      );
}

class _Pick {
  const _Pick({required this.id, required this.name, required this.price});
  final int id;
  final String name;
  final num price;
}
