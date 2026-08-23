import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// One support ticket, as a conversation.
///
/// `ticketSearch` returns the ticket ROWS and nothing else, so a host could be
/// told "support replied" and have nowhere to read it — the reply existed in a
/// thread they had no screen to open. This is that screen, plus the reply box.
class HostTicketThreadScreen extends StatefulWidget {
  const HostTicketThreadScreen({
    super.key,
    required this.ticketId,
    required this.subject,
  });

  final int ticketId;
  final String subject;

  @override
  State<HostTicketThreadScreen> createState() => _HostTicketThreadScreenState();
}

class _HostTicketThreadScreenState extends State<HostTicketThreadScreen> {
  final HostService _service = HostService();
  final _replyCtrl = TextEditingController();
  final _scroll = ScrollController();

  bool _loading = true;
  bool _sending = false;
  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = const [];

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
    _replyCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getSupportThread(widget.ticketId);
    if (!mounted) return;
    setState(() {
      _ticket = data?['ticket'] is Map
          ? Map<String, dynamic>.from(data!['ticket'] as Map)
          : null;
      _messages = data?['messages'] is List
          ? (data!['messages'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [];
      _loading = false;
    });
    // Land on the newest message — the reason the host opened this.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final err = await _service.replySupportTicket(
        ticketId: widget.ticketId, message: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: kDanger),
      );
      return;
    }
    _replyCtrl.clear();
    await _load();
  }

  static String _fmt(dynamic raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse('$raw')?.toLocal();
    if (d == null) return '';
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'am' : 'pm';
    return '${d.day} ${m[d.month]}, $hh:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  @override
  Widget build(BuildContext context) {
    final status = '${_ticket?['status'] ?? ''}';
    // A closed ticket is answered. Reopening it is support's call, so there is
    // nothing to type into — the same rule the web page follows.
    final canReply = status != 'CLOSED' && !_loading;

    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _ticket?['subject']?.toString() ?? widget.subject,
          overflow: TextOverflow.ellipsis,
          style: inter(fontSize: 16, fontWeight: FontWeight.w700, color: kInk),
        ),
      ),
      body: Column(
        children: [
          if (status.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'PENDING'
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
                            color: status == 'PENDING'
                                ? kInk
                                : status == 'RESOLVED'
                                    ? Colors.white
                                    : kInk2)),
                  ),
                  const SizedBox(width: 8),
                  Text('${_ticket?['category'] ?? ''}',
                      style: inter(fontSize: 11.5, color: kMuted)),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text("Couldn't load this conversation.",
                            style: inter(fontSize: 13, color: kMuted)),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) {
                            final m = _messages[i];
                            final mine = '${m['from']}' == 'you';
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                decoration: BoxDecoration(
                                  color: mine ? kIndigo50 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kLine),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${mine ? 'You' : 'Support'} · ${_fmt(m['createdAt'])}',
                                        style: inter(
                                            fontSize: 10.5, color: kMuted)),
                                    const SizedBox(height: 3),
                                    Text('${m['message'] ?? ''}',
                                        style: inter(
                                            fontSize: 13.5,
                                            color: kInk,
                                            height: 1.45)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (canReply)
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: kLine)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      maxLines: 4,
                      minLines: 1,
                      maxLength: 5000,
                      decoration: InputDecoration(
                        hintText: 'Reply to support…',
                        counterText: '',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: kIndigo),
                  ),
                ],
              ),
            )
          else if (!_loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Text(
                'This ticket is closed. Raise a new one if you still need help.',
                textAlign: TextAlign.center,
                style: inter(fontSize: 12.5, color: kMuted),
              ),
            ),
        ],
      ),
    );
  }
}
