
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/data/models/negotiation_model.dart';
import 'package:rent_home/service/negotitation_service.dart';
import 'package:rent_home/ui/screens_common/price_negotiation/negotitaion_page.dart';

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
  /// Two offers each — four messages to the whole negotiation.
  ///
  /// This said 400 while the screen above it read "Messages: 0/4" and "Your
  /// remaining: 400" on the same row, which is what a tester was looking at
  /// when they said negotiations were not working. Four hundred rounds is not
  /// a negotiation, and nothing enforces a cap server-side, so the number
  /// here IS the rule; the original (still in the legacy controller) is two
  /// per side, and the label has been telling guests four all along.
  final RxInt maxMessagesPerUser = 2.obs;

  /// The whole negotiation's budget — what the counter shows as the
  /// denominator. Derived, so the label and the limit cannot drift apart
  /// again.
  int get maxTotalMessages => maxMessagesPerUser.value * 2;
  final RxBool chatLimitReached = false.obs;
  final RxBool isUserTurn = true.obs; // User starts first
  final RxString lastMessageSenderId = ''.obs;

  NegotiationController(this._negotiationService);

  @override
  void onInit() {
    super.onInit();
    _setupSocketListeners();
  }

  final AuthController authController = Get.find<AuthController>();

  //Check if user can send message based on chat limits and turn
  bool canUserSendMessage(String currentUserId, String hostId) {
    final currentUserIdStr = authController.userData.value?.userId.toString();
    // if (lastMsg.isOffer == true &&
    //     currentUserIdStr != null &&
    //     lastMsg.senderId != currentUserIdStr &&
    //     (lastMsg.isAccepted != true)) {
    //   latestForeignOffer = lastMsg;
    // }

    // return true;
    // Global blocking conditions
    if (chatLimitReached.value) {
      //  debugPrint('$logTag ❌ Blocked: chatLimitReached is true');
      return false;
    }

    if (offerFinalized.value) {
      //  debugPrint('$logTag ❌ Blocked: offerFinalized is true');
      return false;
    }

    // 🔐 Turn-based check ONLY if messages exist
    if (messages.isNotEmpty) {
      final lastMsgSenderId = messages.last.senderId;

      // debugPrint('$logTag lastMsgSenderId: $lastMsgSenderId');

      if (lastMsgSenderId.isNotEmpty && lastMsgSenderId == currentUserIdStr) {
        // debugPrint(
        //     '$logTag ❌ Blocked: Same user trying to send consecutive messages');
        return false;
      }
    } else {
      // debugPrint('$logTag No previous messages → first message allowed');
    }

    // Turn-based check (no consecutive messages)
    // if (lastMessageSenderId.value.isNotEmpty &&
    //     lastMessageSenderId.value == currentUserId) {
    //   debugPrint(
    //       '$logTag ❌ Blocked: Same user trying to send consecutive messages');
    //   return false;
    // }
    // if (lastMsgSenderId.isNotEmpty && lastMsgSenderId == currentUserIdStr) {
    //   debugPrint(
    //       '$logTag ❌ Blocked: Same user trying to send consecutive messages');
    //   return false;
    // }

    // Identify sender role
    final isCurrentUserSender = currentUserIdStr != hostId;
    //debugPrint('$logTag isCurrentUserSender: $isCurrentUserSender');

    // Message limit checks
    if (isCurrentUserSender) {
      if (userMessageCount.value >= maxMessagesPerUser.value) {
        // debugPrint('$logTag ❌ Blocked: User message limit reached '
        //     '(${userMessageCount.value}/${maxMessagesPerUser.value})');
        return false;
      }
    } else {
      if (hostMessageCount.value >= maxMessagesPerUser.value) {
        // debugPrint('$logTag ❌ Blocked: Host message limit reached '
        //     '(${hostMessageCount.value}/${maxMessagesPerUser.value})');
        return false;
      }
    }

    //   debugPrint('$logTag ✅ Allowed: User can send message');
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
    if (totalMessages >= maxTotalMessages) {
      chatLimitReached.value = true;
      isUserTurn.value = false; // No more turns
    }
  }

  // Get remaining message count for current user
  int getRemainingMessages(String currentUserId, String hostId) {
    final isUser = currentUserId != hostId;
    final used = isUser ? userMessageCount.value : hostMessageCount.value;
    // Never below zero. History replay can push a count past the cap on an
    // old negotiation started before the limit existed, and "-3 remaining"
    // is not a thing to tell anybody.
    return (maxMessagesPerUser.value - used).clamp(0, maxMessagesPerUser.value);
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
    //connection status listener
    _negotiationService.connectionStatus.listen((status) {
      if (_isDisposed) return;
      connectionStatus.value = status;
      if (status == NegotiationConnectionStatus.error) {
        errorMessage.value = 'Connection error occurred. Please try again.';
      }
    }, onError: (error) {
      if (_isDisposed) return;
      errorMessage.value = 'Connection error: $error';
    });
    // negotiation message listener
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
          updateMessageCounts(message.senderId, message.userId, message.hostId);
        }
      } else {
        messages.add(message);
        updateMessageCounts(message.senderId, message.userId, message.hostId);
      }

// Offer handling
      if (message.isOffer && message.offerPrice != null) {
        // currentPrice.value = message.offerPrice!;
      }

// Accepted handling
      if (message.isAccepted) {
        _applyAccepted(message);
      }
      // if (message.messageId.isNotEmpty) {
      //   final idx =
      //       messages.indexWhere((m) => m.messageId == message.messageId);
      //   if (idx != -1) {
      //     messages[idx] = message;
      //   } else {
      //     messages.add(message);
      //     // Update chat limits for new messages
      //     updateMessageCounts(message.senderId, message.userId, message.hostId);
      //   }
      // } else {
      //   messages.add(message);
      //   // Update chat limits for new messages
      //   updateMessageCounts(message.senderId, message.userId, message.hostId);
      // }
      // if (message.isOffer && message.offerPrice != null) {
      //   currentPrice.value = message.offerPrice!;
      // }
      // if (message.isAccepted) {
      //   _applyAccepted(message);
      // }
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

      // Update currentPrice with the latest offer.
      //
      // This assignment was commented out, so reopening a negotiation showed
      // the listed price as the "current offer" no matter how far the
      // haggling had got — the one place that knows the real standing number
      // was the one place not allowed to say it.
      final latestOffer = messages
          .lastWhereOrNull((msg) => msg.isOffer && msg.offerPrice != null);
      if (latestOffer?.offerPrice != null) {
        currentPrice.value = latestOffer!.offerPrice!;
      }
      final accepted = messages.where((m) => m.isAccepted).toList();
      if (accepted.isNotEmpty) {
        _applyAccepted(accepted.last);
      }
      _stopLoading();
    }, onError: (error) {
      if (_isDisposed) return;
      errorMessage.value = 'Failed to load chat history: $error';
      _stopLoading();
    });
  }

  void connectToSocket(String serverUrl, String token) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _negotiationService.initSocket(serverUrl, token: token);
    } catch (e) {
      errorMessage.value = 'Socket connection error: $e';
      _stopLoading();
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
    String? bookFrom, // DD-MM-YYYY — the stay this offer is for (offers only)
    String? bookTo,
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

      bool isSent = await _negotiationService.sendNegotiationMessage(
          message: message, bookFrom: bookFrom, bookTo: bookTo);
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
      _startLoadWatchdog();
      _negotiationService
          .loadNegotiationChat(senderId, receiverId, propertyId)
          .then((_) {
        if (_isDisposed) return;
        // Only when there IS an offer to show.
        //
        // This used to fall back to 0.0, and it fires when the REQUEST
        // resolves — which is before the chat-history socket event delivers
        // any messages. So on every fresh negotiation it wiped the listed
        // price the screen had just been opened with and rendered
        // "Current Offer ₹0.00" under a "Base: ₹2,900.00" header. The price
        // standing before the first offer is the listed one; leave it alone.
        final latest = messages
            .lastWhereOrNull((msg) => msg.isOffer && msg.offerPrice != null);
        if (latest?.offerPrice != null) {
          currentPrice.value = latest!.offerPrice!;
        }
        // The request is done. This never cleared the flag, so the screen
        // stayed on the spinner until the chat-history socket event happened
        // to arrive — and on a first-time negotiation, where there is no
        // history to send, it never did. Tapping Negotiate showed a loader
        // and a wall of caution text, forever.
        _stopLoading();
      }).catchError((e) {
        if (_isDisposed) return;
        errorMessage.value = 'Error loading negotiation chat: $e';
        _stopLoading();
      });
    } catch (e) {
      errorMessage.value = 'Error loading negotiation chat: $e';
      _stopLoading();
    }
  }

  Timer? _loadWatchdog;

  /// A socket that connects but never emits used to hang the screen with no
  /// way out. An empty negotiation is a perfectly usable screen — you type an
  /// offer into it — so after this the chat opens either way.
  void _startLoadWatchdog() {
    _loadWatchdog?.cancel();
    _loadWatchdog = Timer(const Duration(seconds: 12), () {
      if (_isDisposed || !isLoading.value) return;
      isLoading.value = false;
    });
  }

  void _stopLoading() {
    _loadWatchdog?.cancel();
    _loadWatchdog = null;
    isLoading.value = false;
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
    // Ensure list updated with accepted message
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
      _loadWatchdog?.cancel();
    }
    super.onClose();
  }
}
