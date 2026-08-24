/// One conversation in the inbox: who it is with, and how it stands.
class MessageThread {
  const MessageThread({
    required this.partnerId,
    required this.name,
    this.lastMessage = '',
    this.lastAt,
    this.unread = 0,
  });

  final String partnerId;
  final String name;
  final String lastMessage;
  final DateTime? lastAt;
  final int unread;

  static String _s(dynamic v) => v == null ? '' : v.toString();

  factory MessageThread.fromJson(Map<String, dynamic> j) => MessageThread(
        partnerId: _s(j['partnerId'] ?? j['partner_id']),
        // "User" rather than an empty row: a thread with no resolvable name is
        // still a real conversation the guest needs to be able to open.
        name: _s(j['name']).isEmpty ? 'User' : _s(j['name']),
        lastMessage: _s(j['lastMessage'] ?? j['last_message']),
        lastAt: DateTime.tryParse(_s(j['lastAt'] ?? j['last_at'])),
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}
