/// One host ↔ guest message.
///
/// The socket and the REST rows disagree slightly on field names depending on
/// which side emitted them, so every field is read defensively — a message that
/// arrives in a shape we did not expect should still render rather than crash
/// the conversation.
class ChatMessage {
  const ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.body,
    this.sentAt,
    this.isRead = false,
  });

  final String senderId;
  final String receiverId;
  final String body;
  final DateTime? sentAt;
  final bool isRead;

  bool mineFrom(String me) => senderId == me;

  static String _s(dynamic v) => v == null ? '' : v.toString();

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        senderId: _s(j['sender_id'] ?? j['senderId']),
        receiverId: _s(j['receiver_id'] ?? j['receiverId']),
        body: _s(j['message'] ?? j['body'] ?? j['text']),
        sentAt: DateTime.tryParse(
            _s(j['created_at'] ?? j['createdAt'] ?? j['sent_at'])),
        isRead: j['is_read'] == 1 || j['is_read'] == true || j['isRead'] == true,
      );
}
