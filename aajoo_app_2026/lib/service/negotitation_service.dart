import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:rent_home/controller/negotiation_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:rent_home/models/negotiation_model.dart';

enum NegotiationConnectionStatus { connected, disconnected, error }

class NegotiationService {
  IO.Socket? _socket;
  final _connectionController =
      StreamController<NegotiationConnectionStatus>.broadcast();
  final _negotiationMessageController =
      StreamController<NegotiationMessageModel>.broadcast();
  final _negotiationChatHistoryController =
      StreamController<List<NegotiationMessageModel>>.broadcast();
  bool _isInitialized = false;

  Stream<NegotiationConnectionStatus> get connectionStatus =>
      _connectionController.stream;
  Stream<NegotiationMessageModel> get negotiationMessageStream =>
      _negotiationMessageController.stream;
  Stream<List<NegotiationMessageModel>> get negotiationChatHistoryStream =>
      _negotiationChatHistoryController.stream;

  NegotiationService();
  final logger = Logger();

  Future initSocket(String serverUrl, {required String token}) async {
    if (_isInitialized) return;

    try {
      logger.i("Initializing negotiation socket with token: $token");
      _socket = IO.io(serverUrl, <String, dynamic>{
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

      _socket!.onConnect((_) => _onConnect());
      _socket!.onDisconnect((_) => _onDisconnect());
      _socket!.onConnectError((error) => _onConnectError(error));
      _socket!.on('receiveNegotiationMessage', _onNegotiationMessageReceived);
      _socket!.on('negotiationChatHistory', _onNegotiationChatHistoryReceived);
      _socket!.on('negotiationMessageSent', _onNegotiationMessageSent);
      _socket!.on('offerAccepted', _onOfferAccepted);
      _socket!.on('negotiationError', _onNegotiationError);

      await Future.delayed(const Duration(milliseconds: 100));
      _socket!.connect();
      _isInitialized = true;
    } catch (e) {
      _connectionController.add(NegotiationConnectionStatus.error);
      logger.i('Negotiation socket initialization error: $e');
    }
  }

  // Emit acceptOffer -> backend expects offer_id, property_id, accepter_id
  void acceptOffer({
    required String offerId,
    required String propertyId,
    required String accepterId,
  }) {
    if (!(_socket?.connected ?? false)) {
      logger.w('Cannot emit acceptOffer. Socket not connected');
      return;
    }
    final payload = {
      'offer_id': offerId,
      'property_id': propertyId,
      'accepter_id': accepterId,
    };
    logger.i('emit acceptOffer: $payload');
    try {
      _socket!.emitWithAck('acceptOffer', payload, ack: (data) {
        logger.i('acceptOffer ack: $data');
        try {
          if (data is Map) {
            final success = data['success'] == true;
            if (!success) {
              // Immediate failure -> propagate negotiationError path
              try {
                final controller = Get.find<NegotiationController>();
                controller.onNegotiationError(data);
              } catch (_) {}
            }
          }
        } catch (e) {
          logger.w('Error handling acceptOffer ack: $e');
        }
      });
      // Diagnostic: set a one-time timer to log if no offerAccepted event arrives
      Future.delayed(const Duration(seconds: 6), () {
        if (!Get.isRegistered<NegotiationController>()) return;
        final controller = Get.find<NegotiationController>();
        if (controller.acceptingOffer.value &&
            !controller.offerFinalized.value) {
          logger.w(
              'acceptOffer diagnostic: No offerAccepted event received within 6s for offer $offerId');
        }
      });
    } catch (e) {
      logger.e('acceptOffer emit error: $e');
    }
  }

  void _onConnect() {
    _connectionController.add(NegotiationConnectionStatus.connected);
    logger.i('Negotiation socket connected successfully');
  }

  void _onDisconnect() {
    _connectionController.add(NegotiationConnectionStatus.disconnected);
    logger.i('Negotiation socket disconnected');
  }

  void _onConnectError(error) {
    _connectionController.add(NegotiationConnectionStatus.error);
    logger.i('Negotiation connection error: $error');
  }

  void joinNegotiationRoom(String userId, String propertyId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('joinNegotiation', {
        'userId': userId,
        'propertyId': propertyId,
      });
      logger.i(
          'Joined negotiation room for user: $userId, property: $propertyId');
    } else {
      logger.i('Cannot join negotiation room. Socket not connected.');
      _connectionController.add(NegotiationConnectionStatus.error);
    }
  }

  Future<bool> sendNegotiationMessage({
    required NegotiationMessageModel message,
    String? bookFrom, // DD-MM-YYYY — dates this offer is for (offers only)
    String? bookTo,
    int retryCount = 3,
  }) async {
    if (_socket?.connected ?? false) {
      try {
        final payload = {
          'property_id': message.propertyId,
          'sender_id': message.senderId,
          'receiver_id': message.receiverId,
          'message_text': message.messageText,
          'is_offer': message.isOffer,
          'offer_price': message.offerPrice,
          'userId': message.userId,
          'hostId': message.hostId,
          // Sanctioned-on-accept stay dates. The host accept mints a coupon tied
          // to these (mirrors web's date-aware offer).
          if (message.isOffer && bookFrom != null) 'book_from': bookFrom,
          if (message.isOffer && bookTo != null) 'book_to': bookTo,
        };
        logger.i('emit sendNegotiationMessage: $payload');
        _socket!.emit('sendNegotiationMessage', payload);
        return true;
      } catch (e) {
        logger.i('Error sending negotiation message: $e');
        return false;
      }
    }
    logger.i('Cannot send negotiation message. Socket not connected.');
    return false;
  }

  // Handle sender ack from server and auto-refresh chat
  Future<void> _onNegotiationMessageSent(dynamic data) async {
    try {
      logger.i('negotiationMessageSent ack: $data');
      // Optionally push to the sender stream so UI shows the message immediately
      try {
        final sent =
            NegotiationMessageModel.fromJson(Map<String, dynamic>.from(data));
        // _negotiationMessageController.add(sent);
        // Refresh chat
        await loadNegotiationChat(
            sent.senderId, sent.receiverId, sent.propertyId);
      } catch (_) {}
    } catch (e) {
      logger.i('Error handling negotiationMessageSent: $e');
    }
  }

  void _onNegotiationMessageReceived(dynamic data) {
    try {
      logger.i('Received negotiation message: $data');
      final message = NegotiationMessageModel.fromJson(data);
      _negotiationMessageController.add(message);
    } catch (e) {
      logger.i('Error parsing negotiation message: $e');
      _negotiationMessageController.addError(e);
    }
  }

  Future<void> loadNegotiationChat(
      String senderId, String receiverId, String propertyId) async {
    if (_socket?.connected ?? false) {
      _socket!.emit('loadNegotiationChat', {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'property_id': propertyId,
      });
      logger.i(
          'Requested negotiation chat history for property: $propertyId $senderId->$receiverId');
    } else {
      logger.i('Cannot load negotiation chat. Socket not connected.');
      _negotiationChatHistoryController.addError('Socket not connected');
    }
  }

  void _onNegotiationChatHistoryReceived(dynamic data) {
    try {
      logger.d('Received negotiation chat history: $data');
      List list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['messages'] is List) {
        list = data['messages'];
      } else {
        list = const [];
      }
      final messages = list
          .map((item) => NegotiationMessageModel.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
      _negotiationChatHistoryController.add(messages);
      final controller = Get.find<NegotiationController>();
      controller.currentPrice.value = messages
              .lastWhereOrNull((msg) => msg.isOffer && msg.offerPrice != null)
              ?.offerPrice ??
          0.0;
    } catch (e) {
      logger.i('Error parsing negotiation chat history: $e');
      _negotiationChatHistoryController.addError(e);
    }
  }

  void _onOfferAccepted(dynamic data) {
    try {
      logger.i('offerAccepted event: $data');
      // Data shape: { success: true, offer: { ...updatedOffer } }
      if (data is Map && data['offer'] is Map) {
        final offer = NegotiationMessageModel.fromJson(
            Map<String, dynamic>.from(data['offer'] as Map));
        // Push as single message update
        _negotiationMessageController.add(offer);
        // Refresh chat to sync full list
        loadNegotiationChat(offer.senderId, offer.receiverId, offer.propertyId);
        try {
          final controller = Get.find<NegotiationController>();
          controller.onOfferAccepted(offer);
        } catch (_) {}
      }
    } catch (e) {
      logger.w('Error handling offerAccepted: $e');
    }
  }

  void _onNegotiationError(dynamic data) {
    logger.w('negotiationError: $data');
    try {
      final controller = Get.find<NegotiationController>();
      controller.onNegotiationError(data);
    } catch (_) {}
  }

  void dispose() {
    if (_isInitialized) {
      _socket?.disconnect();
      _socket?.dispose();
      _connectionController.close();
      _negotiationMessageController.close();
      _negotiationChatHistoryController.close();
      _isInitialized = false;
    }
  }
}
