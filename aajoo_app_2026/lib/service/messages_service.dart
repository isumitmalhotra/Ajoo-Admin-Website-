import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/models/chat_message.dart';
import 'package:rent_home/models/message_thread.dart';
import 'package:rent_home/service/auth_service.dart';
import 'package:rent_home/utils/secure_store.dart';

/// Host ↔ guest conversations.
///
/// Distinct from [NegotiationService], which carries OFFERS about one property.
/// These messages are between two people and carry no property at all —
/// `tbl_messages` has sender, receiver and body, nothing else — so a
/// conversation cannot be shown on the property-scoped negotiation screen. That
/// is why the app had no inbox: a chat notification could only be opened when
/// its payload happened to name a property, and otherwise landed on home.
///
/// Same socket contract the web uses (see redesign/lib/useChat.ts):
///   emit join(me) · loadMessages{sender_id,receiver_id} · messageSeen{...}
///        sendMessage{sender_id,receiver_id,message}
///   on   chatHistory · receiveMessage · messageSent
class MessagesService {
  MessagesService._();
  static final MessagesService instance = MessagesService._();

  final _logger = Logger();
  io.Socket? _socket;
  bool _initialised = false;
  String? _me;

  final _historyController = StreamController<List<ChatMessage>>.broadcast();
  final _incomingController = StreamController<ChatMessage>.broadcast();
  final _connectedController = StreamController<bool>.broadcast();

  /// The full conversation, in reply to [loadConversation].
  Stream<List<ChatMessage>> get history => _historyController.stream;

  /// One message arriving — either the partner's, or the echo of our own.
  Stream<ChatMessage> get incoming => _incomingController.stream;

  Stream<bool> get connected => _connectedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// The thread list. REST rather than socket, matching the web.
  Future<List<MessageThread>> threads() async {
    try {
      final token = await secureRead(AuthService().TOKEN_KEY);
      final dio = Dio(BaseOptions(baseUrl: Apiconstants.baseUrl));
      final res = await dio.get(
        '/user/messages/threads',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data is Map ? res.data['data'] : null;
      final raw = (data is Map ? data['threads'] : null) ?? data;
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => MessageThread.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _logger.w('messages: threads failed — $e');
      return const [];
    }
  }

  Future<void> connect({required String myId}) async {
    _me = myId;
    if (_initialised) {
      // Re-announce presence: a socket that survived a screen being closed is
      // still connected but the server may have dropped us from the room.
      if (_socket?.connected ?? false) _socket!.emit('join', myId);
      return;
    }
    try {
      final token = await secureRead(AuthService().TOKEN_KEY);
      _socket = io.io(Apiconstants.serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        // BOTH, deliberately (BE-16). The server reads auth.token first and
        // the Authorization header second: `auth` is the contract the website
        // uses, and the header is what this client has always sent — which the
        // server did not read, so every app socket connected anonymously while
        // looking authenticated from here. Sending both means neither side has
        // to be changed in lockstep again.
        'auth': {'token': token},
        'extraHeaders': {'Authorization': 'Bearer $token'},
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
      });

      _socket!.onConnect((_) {
        _connectedController.add(true);
        // Re-join on every connect, not just the first — a reconnect starts a
        // new session server-side and would otherwise deliver nothing.
        if (_me != null) _socket!.emit('join', _me);
      });
      _socket!.onDisconnect((_) => _connectedController.add(false));
      _socket!.onConnectError((e) {
        _connectedController.add(false);
        _logger.w('messages socket: $e');
      });

      _socket!.on('chatHistory', (data) {
        if (data is List) {
          _historyController.add(data
              .whereType<Map>()
              .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList());
        }
      });
      _socket!.on('receiveMessage', _emitOne);
      _socket!.on('messageSent', _emitOne);

      _socket!.connect();
      _initialised = true;
    } catch (e) {
      _logger.e('messages socket init failed: $e');
      _connectedController.add(false);
    }
  }

  void _emitOne(dynamic data) {
    if (data is Map) {
      _incomingController
          .add(ChatMessage.fromJson(Map<String, dynamic>.from(data)));
    }
  }

  /// Ask for the conversation with [partnerId] and mark their messages seen.
  void loadConversation(String partnerId) {
    final me = _me;
    if (me == null || !(_socket?.connected ?? false)) return;
    _socket!.emit('loadMessages', {'sender_id': me, 'receiver_id': partnerId});
    _socket!.emit('messageSeen', {'sender_id': partnerId, 'receiver_id': me});
  }

  void send({required String partnerId, required String body}) {
    final me = _me;
    final text = body.trim();
    if (me == null || text.isEmpty || !(_socket?.connected ?? false)) return;
    _socket!.emit('sendMessage', {
      'sender_id': me,
      'receiver_id': partnerId,
      'message': text,
    });
  }

  /// Drop the socket — called on logout, so the next account does not inherit
  /// this one's room.
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _initialised = false;
    _me = null;
  }
}
