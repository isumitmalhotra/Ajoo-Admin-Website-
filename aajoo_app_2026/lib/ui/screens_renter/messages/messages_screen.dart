import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/models/chat_message.dart';
import 'package:rent_home/models/message_thread.dart';
import 'package:rent_home/service/messages_service.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/utils/fonts.dart';

/// The guest's message inbox — the mobile counterpart of the web's
/// /account/messages.
///
/// The app had no inbox at all. Conversations existed (the backend has carried
/// host ↔ guest messages all along) but the only place the app could show one
/// was the per-property negotiation thread, which needs a property — and these
/// messages have none. So a chat notification could only be opened when its
/// payload happened to name a property, and every other conversation was
/// unreachable from the phone.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.openWith, this.openWithName});

  /// Deep-link straight into one conversation (from a notification, or
  /// "Contact host"), even when no thread exists for them yet.
  final String? openWith;
  final String? openWithName;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _svc = MessagesService.instance;
  List<MessageThread> _threads = const [];
  bool _loading = true;
  String? _me;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final id = auth?.userData.value?.userId;
    _me = id?.toString();
    if (_me != null) await _svc.connect(myId: _me!);
    final rows = await _svc.threads();
    if (!mounted) return;
    setState(() {
      _threads = rows;
      _loading = false;
    });

    // A deep-linked partner may have no thread yet — show it anyway so the
    // conversation is usable before the first message is sent.
    final want = widget.openWith;
    if (want != null && want.isNotEmpty) {
      final existing = _threads.where((t) => t.partnerId == want).firstOrNull;
      _open(existing ??
          MessageThread(
              partnerId: want, name: widget.openWithName ?? 'Host'));
    }
  }

  void _open(MessageThread t) {
    if (_me == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => _ConversationScreen(thread: t, me: _me!),
        ))
        // Unread counts change while you are in there.
        .then((_) => _refresh());
  }

  Future<void> _refresh() async {
    final rows = await _svc.threads();
    if (!mounted) return;
    setState(() => _threads = rows);
  }

  String _when(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        foregroundColor: kInk,
        title: Text('Messages',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _threads.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: kInk.withOpacity(.06)),
                    itemBuilder: (_, i) => _row(_threads[i]),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 48, color: kMuted),
              const SizedBox(height: 12),
              Text('No messages yet',
                  style: fraunces(
                      fontSize: 17, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 6),
              Text(
                'Messages with your hosts appear here. Open a stay and tap '
                'Contact host to start one.',
                textAlign: TextAlign.center,
                style: inter(fontSize: 13.5, color: kMuted, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _row(MessageThread t) {
    final unread = t.unread > 0;
    return ListTile(
      onTap: () => _open(t),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: kInk.withOpacity(.08),
        child: Text(
          t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
          style: fraunces(
              fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
        ),
      ),
      title: Text(t.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: inter(
              fontSize: 14.5,
              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
              color: kInk)),
      subtitle: Text(
        t.lastMessage.isEmpty ? 'No messages yet' : t.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: inter(
            fontSize: 13,
            color: unread ? kInk : kMuted,
            fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_when(t.lastAt), style: inter(fontSize: 11.5, color: kMuted)),
          if (unread) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: kInk, borderRadius: BorderRadius.circular(999)),
              child: Text('${t.unread}',
                  style: inter(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

/// One conversation.
class _ConversationScreen extends StatefulWidget {
  const _ConversationScreen({required this.thread, required this.me});

  final MessageThread thread;
  final String me;

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _svc = MessagesService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  StreamSubscription<List<ChatMessage>>? _historySub;
  StreamSubscription<ChatMessage>? _incomingSub;

  @override
  void initState() {
    super.initState();
    _historySub = _svc.history.listen((rows) {
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(rows.where(_belongsHere));
        _loading = false;
      });
      _toBottom();
    });
    _incomingSub = _svc.incoming.listen((m) {
      if (!mounted || !_belongsHere(m)) return;
      setState(() => _messages.add(m));
      _toBottom();
    });
    _svc.loadConversation(widget.thread.partnerId);
    // The socket may answer nothing at all (no history yet). Don't spin forever.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _loading) setState(() => _loading = false);
    });
  }

  /// Both streams are app-wide, so a message for a DIFFERENT conversation can
  /// arrive while this one is open — it must not be appended here.
  bool _belongsHere(ChatMessage m) {
    final p = widget.thread.partnerId;
    return (m.senderId == p && m.receiverId == widget.me) ||
        (m.senderId == widget.me && m.receiverId == p);
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _svc.send(partnerId: widget.thread.partnerId, body: text);
    _input.clear();
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _incomingSub?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        foregroundColor: kInk,
        title: Text(widget.thread.name,
            style: fraunces(
                fontSize: 17, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'No messages yet — say hello.',
                            textAlign: TextAlign.center,
                            style: inter(fontSize: 13.5, color: kMuted),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _bubble(_messages[i]),
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: kInk.withOpacity(.08))),
              ),
              child: Row(
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
                        hintText: 'Message',
                        hintStyle: inter(fontSize: 14, color: kMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: kInk.withOpacity(.12)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: kInk,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(Icons.send_rounded,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.mineFrom(widget.me);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? kInk : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: kInk.withOpacity(.08)),
        ),
        child: Text(
          m.body,
          style: inter(
              fontSize: 14,
              height: 1.4,
              color: mine ? Colors.white : kInk),
        ),
      ),
    );
  }
}
