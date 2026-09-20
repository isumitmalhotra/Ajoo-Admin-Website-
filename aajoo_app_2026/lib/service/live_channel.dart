import 'dart:async';

import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:rent_home/data/ApiConstants.dart';
import 'package:rent_home/service/auth_service.dart';
import 'package:rent_home/utils/secure_store.dart';

/// One event from the server's per-person room.
class LiveEvent {
  const LiveEvent(this.name, this.data);
  final String name;
  final dynamic data;
}

/// ONE socket per signed-in person, for the things the server tells a
/// person about — not a chat room.
///
/// The 300-case run (batch 6, 2026-09-20, NG-022) watched a host's
/// Negotiations list on this app while the guest countered from the website:
/// nothing moved until pull-to-refresh, and after the host's own counter the
/// card kept its Accept/Counter/Decline. The website flips its card the
/// moment the server emits; the app had two sockets (chat, negotiation
/// chat) and neither was open on that screen nor subscribed to any of
/// `negotiation:*` / `notification:new`.
///
/// The server joins every authenticated socket to `user_<id>` on the
/// handshake and emits these to it:
///
///   negotiation:new_offer        host   — a guest's offer reached them
///   negotiation:guest_reply      host   — accept / decline / counter-back
///   negotiation:host_reply       guest  — the host answered
///   negotiation:auto_countered   both   — the platform answered round one
///   negotiation:auto_booked      both   — a deal was booked
///   notification:new             either — a bell row was written
///
/// Screens subscribe with [on] and reload themselves; this class carries no
/// screen state. Connected after sign-in and when a session is restored on
/// launch, dropped at sign-out (the room is the person's, and the next
/// account must not inherit it).
class LiveChannel {
  LiveChannel._();
  static final LiveChannel instance = LiveChannel._();

  static const negotiationEvents = {
    'negotiation:new_offer',
    'negotiation:guest_reply',
    'negotiation:host_reply',
    'negotiation:auto_countered',
    'negotiation:auto_booked',
  };
  static const notificationEvent = 'notification:new';
  static const allEvents = {...negotiationEvents, notificationEvent};

  final _logger = Logger();
  io.Socket? _socket;
  String? _token;
  final _events = StreamController<LiveEvent>.broadcast();

  Stream<LiveEvent> get events => _events.stream;

  /// Events whose name is in [names].
  Stream<LiveEvent> on(Iterable<String> names) {
    final wanted = names.toSet();
    return _events.stream.where((e) => wanted.contains(e.name));
  }

  bool get isConnected => _socket?.connected ?? false;

  /// Open (or keep) the socket for the stored session. Safe to call from any
  /// screen: a second call with the same token is a no-op, a different token
  /// (another account signed in) replaces the socket.
  Future<void> connect() async {
    String? token;
    try {
      token = await secureRead(AuthService().TOKEN_KEY);
    } catch (e) {
      _logger.w('live channel: no session token — $e');
      return;
    }
    if (token == null || token.isEmpty) return;
    if (_socket != null && _token == token) {
      if (!(_socket!.connected)) _socket!.connect();
      return;
    }
    dispose();
    _token = token;
    try {
      // The same handshake the chat socket uses (BE-16): `auth.token` is
      // what the server reads; the header is what this client always sent.
      final s = io.io(Apiconstants.serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
        'extraHeaders': {'Authorization': 'Bearer $token'},
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 10000,
      });
      for (final name in allEvents) {
        s.on(name, (data) => _events.add(LiveEvent(name, data)));
      }
      s.onConnectError((e) => _logger.w('live channel: $e'));
      s.connect();
      _socket = s;
    } catch (e) {
      _logger.e('live channel init failed: $e');
      _socket = null;
      _token = null;
    }
  }

  /// Drop the socket. Called at sign-out; the stream itself stays open so
  /// screens keep their subscriptions across accounts.
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _token = null;
  }
}

/// Reload a screen at most once per [gap] however many events arrive.
///
/// A counter-back writes a row and a bell entry and the server emits for
/// each; two reloads a second apart are a flicker, not information.
class LiveReload {
  LiveReload(this.reload, {this.gap = const Duration(milliseconds: 600)});
  final Future<void> Function() reload;
  final Duration gap;
  Timer? _timer;

  void poke() {
    _timer?.cancel();
    _timer = Timer(gap, () => reload());
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
