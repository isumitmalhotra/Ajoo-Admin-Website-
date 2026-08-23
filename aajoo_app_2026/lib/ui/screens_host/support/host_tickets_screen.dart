import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/ui/screens_host/support/host_ticket_thread_screen.dart';
import 'package:rent_home/utils/fonts.dart';

/// Raise a support ticket, and see what came back.
///
/// The app's Support screen was a WhatsApp/chat launcher and nothing else. The
/// ticket endpoints shipped with the web host portal and the app never called
/// them, so an issue raised from a phone left no record anyone could track and
/// no thread to follow.
///
/// `category` is required by the server and must be one of its enum values.
/// The web form omitted it for months and every ticket was refused with a bare
/// "category is required" — which is exactly why it is a picker here rather
/// than a free-text box.
class HostTicketsScreen extends StatefulWidget {
  const HostTicketsScreen({super.key});

  @override
  State<HostTicketsScreen> createState() => _HostTicketsScreenState();
}

class _HostTicketsScreenState extends State<HostTicketsScreen> {
  final HostService _service = HostService();
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'GENERAL';

  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _tickets = const [];

  /// The five the server's enum accepts. Anything else is refused.
  static const _categories = <String, String>{
    'BOOKING': 'Booking',
    'PAYOUT': 'Payout',
    'PROFILE': 'Profile & account',
    'GENERAL': 'General',
    'OTHER': 'Something else',
  };

  static const _statusText = <String, String>{
    'OPEN': 'Open',
    'PENDING': 'Support replied',
    'RESOLVED': 'Resolved',
    'CLOSED': 'Closed',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getSupportTickets();
    if (!mounted) return;
    setState(() {
      _tickets = list;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final err = await _service.createSupportTicket(
      subject: _subjectCtrl.text.trim(),
      category: _category,
      message: _messageCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Ticket raised — support has been notified.'),
      backgroundColor: err != null ? kDanger : kSuccess,
    ));
    if (err == null) {
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() => _category = 'GENERAL');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text('Support tickets',
            style:
                inter(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kLine),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Raise a ticket',
                        style: inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectCtrl,
                      decoration: _dec('Subject *', 'What do you need help with?'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'A subject is required';
                        // The server's own minimum, checked here so the host is
                        // told before they wait on a round trip.
                        if (t.length < 3) return 'Give the subject a few more words';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: _dec('Category *', null),
                      items: _categories.entries
                          .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value,
                                  style: inter(fontSize: 14, color: kInk))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _category = v ?? 'GENERAL'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 4,
                      maxLength: 5000,
                      decoration: _dec('Message *', 'Describe your issue…'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'A message is required';
                        if (t.length < 10) {
                          return 'Tell us a little more — at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kIndigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                        child: Text(_saving ? 'Sending…' : 'Create ticket',
                            style: inter(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Your tickets',
                style: inter(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kLine),
                ),
                child: Center(
                  child: Text('No tickets yet.',
                      style: inter(fontSize: 13, color: kMuted)),
                ),
              )
            else
              ..._tickets.map(_ticketCard),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, String? hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: inter(fontSize: 13, color: kMuted),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _ticketCard(Map<String, dynamic> t) {
    final status = '${t['st_status'] ?? 'OPEN'}';
    final replied = status == 'PENDING';
    final id = int.tryParse('${t['st_id'] ?? ''}') ?? 0;
    final subject = '${t['st_subject'] ?? 'Support ticket'}';
    return InkWell(
      // Opens the conversation. Without this the list said a ticket existed
      // and gave no way to read what support had said back.
      onTap: id == 0
          ? null
          : () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    HostTicketThreadScreen(ticketId: id, subject: subject),
              ));
              // The thread may have moved the status on, and reading it clears
              // the unread flag — so the list is stale on the way back.
              if (mounted) _load();
            },
      borderRadius: BorderRadius.circular(14),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${t['st_subject'] ?? 'Support ticket'}',
                    style: inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  // "Support replied" is the one a host should act on, so it
                  // is the one that stands out.
                  color: replied
                      ? kClay
                      : status == 'RESOLVED'
                          ? kSuccess
                          : kLine,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(_statusText[status] ?? status,
                    style: inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: replied
                            ? kInk
                            : status == 'RESOLVED'
                                ? Colors.white
                                : kInk2)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text('${t['st_category'] ?? ''}',
                  style: inter(fontSize: 11.5, color: kMuted)),
              const Spacer(),
              Text('View conversation',
                  style: inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kIndigo)),
              const Icon(Icons.chevron_right_rounded, size: 16, color: kIndigo),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
