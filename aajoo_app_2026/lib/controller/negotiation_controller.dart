import 'package:flutter/material.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:rent_home/models/negotiation_model.dart';
import 'package:rent_home/service/negotitation_service.dart';

class NegotiationController extends GetxController {
  final NegotiationService _negotiationService;
  final Rx<NegotiationConnectionStatus> connectionStatus =
      NegotiationConnectionStatus.disconnected.obs;
  final RxList<NegotiationMessageModel> messages =
      <NegotiationMessageModel>[].obs;
  final RxDouble currentPrice = 0.0.obs; // Reactive current price
  final RxBool isLoading = false.obs;
  final RxBool isRoomJoined = false.obs;
  final RxString errorMessage = ''.obs;
  RxString finalAmount = '0.0'.obs;
  // Acceptance state
  final RxString acceptedOfferId = ''.obs;
  final RxBool offerFinalized = false.obs;
  final RxBool acceptingOffer = false.obs;
  bool _isDisposed = false;
  Timer? _acceptOfferTimeout; // timeout watchdog for accept offer

  // Chat limits
  final RxInt userMessageCount = 0.obs;
  final RxInt hostMessageCount = 0.obs;
  final RxInt maxMessagesPerUser = 2.obs;
  final RxBool chatLimitReached = false.obs;
  final RxBool isUserTurn = true.obs; // User starts first
  final RxString lastMessageSenderId = ''.obs;

  NegotiationController(this._negotiationService);

  @override
  void onInit() {
    super.onInit();
    _setupSocketListeners();
  }

  // Check if user can send message based on chat limits and turn
  bool canUserSendMessage(String currentUserId, String hostId) {
    if (chatLimitReached.value || offerFinalized.value) {
      return false;
    }

    // Check if it's user's turn (can't send consecutive messages)
    if (lastMessageSenderId.value == currentUserId &&
        lastMessageSenderId.value.isNotEmpty) {
      return false;
    }

    // Check if user has reached their message limit
    final isCurrentUserSender = currentUserId != hostId;
    if (isCurrentUserSender &&
        userMessageCount.value >= maxMessagesPerUser.value) {
      return false;
    }
    if (!isCurrentUserSender &&
        hostMessageCount.value >= maxMessagesPerUser.value) {
      return false;
    }

    return true;
  }

  // Update message counts and turn tracking
  void updateMessageCounts(String senderId, String userId, String hostId) {
    final isUserMessage = senderId == userId;

    if (isUserMessage) {
      userMessageCount.value++;
    } else {
      hostMessageCount.value++;
    }

    lastMessageSenderId.value = senderId;
    isUserTurn.value = !isUserMessage;

    // Check if chat limit is reached
    final totalMessages = userMessageCount.value + hostMessageCount.value;
    if (totalMessages >= (maxMessagesPerUser.value * 2)) {
      chatLimitReached.value = true;
      isUserTurn.value = false; // No more turns
    }
  }

  // Get remaining message count for current user
  int getRemainingMessages(String currentUserId, String hostId) {
    final isUser = currentUserId != hostId;
    if (isUser) {
      return maxMessagesPerUser.value - userMessageCount.value;
    } else {
      return maxMessagesPerUser.value - hostMessageCount.value;
    }
  }

  // Get whose turn it is
  String getWhoseTurn(String userId, String hostId) {
    if (chatLimitReached.value) {
      return "Chat limit reached - must accept offer";
    }

    if (lastMessageSenderId.value.isEmpty) {
      return "Your turn to make an offer";
    }

    final lastWasUser = lastMessageSenderId.value == userId;
    if (lastWasUser) {
      return "Waiting for host response";
    } else {
      return "Your turn to respond";
    }
  }

  void _setupSocketListeners() {
    _negotiationService.connectionStatus.listen((status) {
      if (_isDisposed) return;
      connectionStatus.value = status;
      if (status == NegotiationConnectionStatus.error) {
        errorMessage.value = 'Connection error occurred. Please try again.';
      }
    }, onError: (error) {
      if (_isDisposed) return;
      print('Negotiation connection status error: $error');
      errorMessage.value = 'Connection error: $error';
    });

    _negotiationService.negotiationMessageStream.listen((message) {
      if (_isDisposed) return;
      // Merge or append by messageId
      if (message.messageId.isNotEmpty) {
        final idx =
            messages.indexWhere((m) => m.messageId == message.messageId);
        if (idx != -1) {
          messages[idx] = message;
        } else {
          messages.add(message);
          // Update chat limits for new messages
          updateMessageCounts(message.senderId, message.userId, message.hostId);
        }
      } else {
        messages.add(message);
        // Update chat limits for new messages
        updateMessageCounts(message.senderId, message.userId, message.hostId);
      }
      if (message.isOffer && message.offerPrice != null) {
        currentPrice.value = message.offerPrice!;
      }
      if (message.isAccepted) {
        _applyAccepted(message);
      }
    }, onError: (error) {
      if (_isDisposed) return;
      print('Negotiation message stream error: $error');
      errorMessage.value = 'Message stream error: $error';
    });

    _negotiationService.negotiationChatHistoryStream.listen((messages) {
      if (_isDisposed) return;
      this.messages.assignAll(messages);

      // Reset and recalculate message counts
      userMessageCount.value = 0;
      hostMessageCount.value = 0;
      lastMessageSenderId.value = '';
      chatLimitReached.value = false;
      isUserTurn.value = true;

      // Count existing messages and update limits
      for (final message in messages) {
        updateMessageCounts(message.senderId, message.userId, message.hostId);
      }

      // Update currentPrice with the latest offer
      final latestOffer = messages
          .lastWhereOrNull((msg) => msg.isOffer && msg.offerPrice != null);
      if (latestOffer != null) {
        currentPrice.value = latestOffer.offerPrice!;
      }
      final accepted = messages.where((m) => m.isAccepted).toList();
      if (accepted.isNotEmpty) {
        _applyAccepted(accepted.last);
      }
      isLoading.value = false;
    }, onError: (error) {
      if (_isDisposed) return;
      print('Negotiation chat history stream error: $error');
      errorMessage.value = 'Failed to load chat history: $error';
      isLoading.value = false;
    });
  }

  void connectToSocket(String serverUrl, String token) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _negotiationService.initSocket(serverUrl, token: token);
    } catch (e) {
      print('Negotiation socket connection error: $e');
      errorMessage.value = 'Socket connection error: $e';
      isLoading.value = false;
    }
  }

  void joinNegotiationRoom(String userId, String propertyId) {
    if (_isDisposed) return;
    try {
      _negotiationService.joinNegotiationRoom(userId, propertyId);
      isRoomJoined.value = true;
    } catch (e) {
      print('Error joining negotiation room: $e');
      errorMessage.value = 'Error joining negotiation room: $e';
    }
  }

  Future<void> sendNegotiationMessage({
    required String propertyId,
    required String senderId,
    required String receiverId,
    required String messageText,
    required bool isOffer,
    double? offerPrice,
    required String userId,
    required String hostId,
    BuildContext? context,
  }) async {
    if (_isDisposed) return;

    // Check chat limits before sending
    if (!canUserSendMessage(senderId, hostId)) {
      String errorMsg;
      if (chatLimitReached.value) {
        errorMsg =
            'Chat limit reached (4 messages total). Please accept the latest offer.';
      } else if (lastMessageSenderId.value == senderId &&
          lastMessageSenderId.value.isNotEmpty) {
        errorMsg =
            'Wait for the other party to respond before sending another message.';
      } else {
        final remaining = getRemainingMessages(senderId, hostId);
        errorMsg =
            'You have reached your message limit ($remaining remaining).';
      }

      errorMessage.value = errorMsg;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
      return;
    }

    try {
      final message = NegotiationMessageModel(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        propertyId: propertyId,
        senderId: senderId,
        receiverId: receiverId,
        messageText: messageText,
        isOffer: isOffer,
        offerPrice: offerPrice,
        createdAt: DateTime.now().toIso8601String(),
        userId: userId,
        hostId: hostId,
      );

      bool isSent =
          await _negotiationService.sendNegotiationMessage(message: message);
      currentPrice.value = offerPrice ?? currentPrice.value;
      if (!isSent) {
        errorMessage.value = 'Failed to send negotiation message';
        // Optionally remove the message if sending failed
        messages.remove(message);
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to send message. Please try again.')),
          );
        }
      }
    } catch (e) {
      print('Error sending negotiation message: $e');
      errorMessage.value = 'Error sending negotiation message: $e';
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> loadNegotiationChat({
    required String senderId,
    required String receiverId,
    required String propertyId,
  }) async {
    if (_isDisposed) return;
    try {
      isLoading.value = true;
      errorMessage.value = '';
      _negotiationService
          .loadNegotiationChat(senderId, receiverId, propertyId)
          .then((_) {
        currentPrice.value = messages
                .lastWhereOrNull((msg) => msg.isOffer && msg.offerPrice != null)
                ?.offerPrice ??
            0.0;
      });
    } catch (e) {
      print('Error loading negotiation chat: $e');
      errorMessage.value = 'Error loading negotiation chat: $e';
      isLoading.value = false;
    }
  }

  void disconnectSocket() {
    if (_isDisposed) return;
    try {
      _negotiationService.dispose();
      connectionStatus.value = NegotiationConnectionStatus.disconnected;
      isRoomJoined.value = false;
      errorMessage.value = '';
      messages.clear();
      currentPrice.value = 0.0;
      acceptedOfferId.value = '';
      offerFinalized.value = false;
      acceptingOffer.value = false;
      // Reset chat limits
      userMessageCount.value = 0;
      hostMessageCount.value = 0;
      chatLimitReached.value = false;
      isUserTurn.value = true;
      lastMessageSenderId.value = '';
    } catch (e) {
      print('Error during negotiation socket disconnection: $e');
      errorMessage.value = 'Error during socket disconnection: $e';
    }
  }

  // Emit accept offer via service
  void acceptOffer(
      {required NegotiationMessageModel offer, required String currentUserId}) {
    if (_isDisposed) return;
    if (offerFinalized.value) return;
    if (acceptingOffer.value) return;
    acceptingOffer.value = true;
    errorMessage.value = '';
    // Start timeout watchdog (e.g., 8 seconds)
    _acceptOfferTimeout?.cancel();
    _acceptOfferTimeout = Timer(const Duration(seconds: 8), () {
      if (!_isDisposed && acceptingOffer.value) {
        acceptingOffer.value = false;
        errorMessage.value =
            'Accepting offer is taking longer than expected. Please try again.';
        Get.snackbar('Negotiation', errorMessage.value,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
            colorText: Get.theme.colorScheme.error);
      }
    });
    _negotiationService.acceptOffer(
      offerId: offer.messageId,
      propertyId: offer.propertyId,
      accepterId: currentUserId,
    );
  }

  // Called by service on offerAccepted event
  void onOfferAccepted(NegotiationMessageModel acceptedMessage) {
    if (_isDisposed) return;
    _applyAccepted(acceptedMessage);
  }

  void _applyAccepted(NegotiationMessageModel acceptedMessage) {
    acceptedOfferId.value = acceptedMessage.messageId;
    offerFinalized.value = true;
    finalAmount.value =
        (acceptedMessage.offerPrice ?? currentPrice.value).toStringAsFixed(2);
    acceptingOffer.value = false;
    _acceptOfferTimeout?.cancel();
    // Ensure list updated
    final idx =
        messages.indexWhere((m) => m.messageId == acceptedMessage.messageId);
    if (idx != -1) {
      messages[idx] = acceptedMessage;
    } else {
      messages.add(acceptedMessage);
    }
  }

  void onNegotiationError(dynamic data) {
    if (_isDisposed) return;
    acceptingOffer.value = false;
    _acceptOfferTimeout?.cancel();
    if (data is Map && data['message'] != null) {
      errorMessage.value = data['message'].toString();
    } else if (data is String) {
      errorMessage.value = data;
    } else {
      errorMessage.value = 'Negotiation error occurred';
    }
    // Surface UI feedback
    if (errorMessage.isNotEmpty) {
      Get.snackbar('Negotiation', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error);
    }
  }

  @override
  void onClose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _negotiationService.dispose();
      _acceptOfferTimeout?.cancel();
    }
    super.onClose();
  }
}
