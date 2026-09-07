// The guest's own support tickets — the half that was missing.
//
// Tickets could be RAISED from the app (the safety flow, the chatbot) and the
// reply had nowhere to appear: Help & Support was an FAQ, a chat widget and
// three contact links. The safety screen literally told people "you can follow
// it in Help & Support", which was not true. The website has had the list, the
// thread and the reply box for months; this is the same three things.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/service/guest_ticket_service.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/safe_bottom.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<GuestTicket> _tickets = const [];
  bool _loading = true;
  /// The load failed. Distinct from "there are none" — see the service.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await GuestTicketService.instance.list();
    if (!mounted) return;
    setState(() {
      _failed = rows == null;
      _tickets = rows ?? const [];
      _loading = false;
    });
  }

  String _when(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(d);
  }

  Color _tone(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'CLOSED':
        return kMuted;
      case 'PENDING':
        return const Color(0xFFB54708);
      default:
        return kprimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        foregroundColor: kInk,
        centerTitle: true,
        title: Text('Your tickets',
            style:
                fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _tickets.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
                      children: [
                        Icon(
                            _failed
                                ? Icons.wifi_off_rounded
                                : Icons.confirmation_number_outlined,
                            size: 44,
                            color: kMuted.withOpacity(0.6)),
                        const SizedBox(height: 14),
                        Text(_failed ? "Couldn't load your tickets" : 'Nothing here yet',
                            textAlign: TextAlign.center,
                            style: fraunces(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                        const SizedBox(height: 8),
                        Text(
                          _failed
                              // Never "there is nothing here" when we do not
                              // know. Somebody who raised a safety report and
                              // is told it is not there concludes it vanished.
                              ? 'Something went wrong reaching us. Pull down to '
                                  'try again — nothing you sent has been lost.'
                              : 'When you raise something with us — a question, or a '
                                  'safety report — it appears here with our reply.',
                          textAlign: TextAlign.center,
                          style:
                              inter(fontSize: 13.5, color: kMuted, height: 1.6),
                        ),
                        if (_failed) ...[
                          const SizedBox(height: 18),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _loading = true);
                                _load();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text('Try again',
                                  style: inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ],
                    )
                  : ListView.separated(
                      padding: safeBottomInsets(context,
                          left: 16, top: 12, right: 16, bottom: 24),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _row(_tickets[i]),
                    ),
            ),
    );
  }

  Widget _row(GuestTicket t) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _TicketThreadScreen(ticket: t)),
        );
        // The unread badge is stale the moment the thread is opened.
        _load();
      },
      child: Container(
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
                // A safety report is not a question about an invoice, and the
                // guest's own list should say so too.
                if (t.isSafety)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE4E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('SAFETY',
                        style: inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF912018))),
                  ),
                Text(t.status,
                    style: inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _tone(t.status))),
                const Spacer(),
                if (t.unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kprimaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${t.unread} new',
                        style: inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(t.subject,
                style: inter(
                    fontSize: 14.5, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 4),
            Text('${t.reference} · ${_when(t.lastReplyAt)}',
                style: inter(fontSize: 12, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

/// One ticket, its messages, and the box to answer in.
class _TicketThreadScreen extends StatefulWidget {
  const _TicketThreadScreen({required this.ticket});
  final GuestTicket ticket;

  @override
  State<_TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends State<_TicketThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<TicketMessage>? _messages;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await GuestTicketService.instance.thread(widget.ticket.id);
    if (!mounted) return;
    setState(() => _messages = rows ?? const []);
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final ok = await GuestTicketService.instance.reply(widget.ticket.id, text);
    if (!mounted) return;
    if (ok) {
      _input.clear();
      await _load();
    } else {
      setState(() => _error = "Couldn't send that. Try again in a moment.");
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final closed = {'RESOLVED', 'CLOSED'}
        .contains(widget.ticket.status.toUpperCase());
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        foregroundColor: kInk,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ticket.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fraunces(
                    fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
            Text('${widget.ticket.reference} · ${widget.ticket.status}',
                style: inter(fontSize: 11.5, color: kMuted)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages!.length,
                    itemBuilder: (_, i) => _bubble(_messages![i]),
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: inter(fontSize: 12.5, color: const Color(0xFFB42318))),
            ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: kLine)),
            ),
            padding: safeBottomInsets(context,
                left: 12, top: 10, right: 12, bottom: 10),
            child: closed
                // A resolved ticket is history. Saying so beats a box that
                // takes a message nobody is waiting for.
                ? Text(
                    'This ticket is ${widget.ticket.status.toLowerCase()}. '
                    'Raise a new one if you still need us.',
                    textAlign: TextAlign.center,
                    style: inter(fontSize: 12.5, color: kMuted),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: inter(fontSize: 14, color: kInk),
                          decoration: InputDecoration(
                            hintText: 'Write a reply…',
                            hintStyle: inter(fontSize: 13.5, color: kMuted),
                            filled: true,
                            fillColor: kCream,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kLine),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kLine),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18),
                        style: IconButton.styleFrom(
                            backgroundColor: kprimaryColor,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(TicketMessage m) {
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: m.mine ? kprimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: m.mine ? null : Border.all(color: kLine),
        ),
        child: Column(
          crossAxisAlignment:
              m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!m.mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Aajoo support',
                    style: inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kprimaryColor)),
              ),
            Text(m.body,
                style: inter(
                    fontSize: 14,
                    height: 1.5,
                    color: m.mine ? Colors.white : kInk)),
            if (m.at != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(DateFormat('d MMM, h:mm a').format(m.at!),
                    style: inter(
                        fontSize: 10.5,
                        color: m.mine ? Colors.white70 : kMuted)),
              ),
          ],
        ),
      ),
    );
  }
}
