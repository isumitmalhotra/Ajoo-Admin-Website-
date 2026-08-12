import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import '../../../../service/verify_service.dart';
import '../auth_controller.dart';

/// Drives the DIDIT identity-verification step.
///
/// Flow: create a session → open DIDIT's hosted flow in the system browser
/// (camera works natively there, unlike an in-app webview) → when the user
/// returns and taps "I've finished", poll the decision (active pull first,
/// then DB status). `renter_kyc`/`host_kyc` finish to the dashboard; `guest_kyc`
/// returns the verified result to the caller (booking checkout).
class KycController extends GetxController {
  final VerifyService _service = VerifyService();

  final String context; // renter_kyc | host_kyc | guest_kyc
  final bool isHost;
  final int? bookingId;
  // When true (e.g. the booking gate), finishing returns a bool result to the
  // caller via Get.back instead of navigating to a dashboard.
  final bool returnResult;

  /// Re-verify on purpose, ignoring the server's 90-day skip. Set when the
  /// user asked to update their documents from the profile (A-66) — without
  /// it the server declines to make a session for an already-verified user.
  final bool force;

  KycController({
    required this.context,
    required this.isHost,
    this.bookingId,
    this.returnResult = false,
    this.force = false,
  });

  // idle | starting | launched | polling | verified | in_review | declined | error
  final RxString status = 'idle'.obs;
  final RxBool busy = false.obs;
  String? _sessionId;

  bool get isGuestContext => context == 'guest_kyc';

  /// Step 1 — create the session and open the hosted flow in the browser.
  Future<void> startVerification() async {
    try {
      busy.value = true;
      status.value = 'starting';
      final session = await _service.createSession(
        context: context,
        bookingId: bookingId,
        force: force,
      );
      _sessionId = session['sessionId']?.toString();
      final url = session['sessionUrl']?.toString();

      // Already verified inside the server's validity window, so it declined
      // to open a session. That is a success, not an outage — it used to fall
      // into the branch below and tell a verified user that verification was
      // temporarily unavailable (A-66).
      if (session['alreadyVerified'] == true) {
        status.value = 'verified';
        showAlert('Already verified',
            'Your identity is already verified. Nothing to do.', false);
        _finish(verified: true);
        return;
      }

      // DIDIT not configured server-side (stub) — don't block the flow.
      if (session['stub'] == true || url == null || url.isEmpty) {
        showAlert('Verification unavailable',
            'Identity verification is temporarily unavailable. You can continue and verify later.', false);
        _finish(verified: false);
        return;
      }

      final opened = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!opened) {
        status.value = 'error';
        showAlert('Error', "Couldn't open the verification page.", true);
        return;
      }
      status.value = 'launched';
    } catch (e) {
      status.value = 'error';
      showAlert('Error', e.toString().replaceAll('Exception: ', ''), true);
    } finally {
      busy.value = false;
    }
  }

  /// Step 2 — after the user completes the flow in the browser and returns.
  Future<void> pollDecision() async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      showAlert('Error', 'No verification session found. Please start again.', true);
      status.value = 'idle';
      return;
    }
    try {
      busy.value = true;
      status.value = 'polling';
      // First call actively pulls the decision from DIDIT (don't wait for webhook).
      String st = 'pending';
      try {
        st = await _service.checkSession(_sessionId!);
      } catch (_) {}
      for (int i = 0; i < 8 && !_isTerminal(st); i++) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          st = await _service.getStatus(_sessionId!);
        } catch (_) {}
      }

      if (_isVerified(st)) {
        status.value = 'verified';
        showAlert('Verified', 'Your identity has been verified.', false);
        _finish(verified: true);
      } else if (st == 'declined') {
        status.value = 'declined';
        showAlert('Verification failed',
            "We couldn't verify your identity. Please try again.", true);
      } else {
        // pending / in_review.
        //
        // This used to say "You can continue meanwhile" and then hand back
        // verified: false — and the booking gate that called it immediately
        // blocked with "Verification required". The guest was told two
        // opposite things within a second and their booking was dropped, which
        // is what "I did the KYC and didn't get back to my booking" describes.
        //
        // The gate is a compliance check, so it is not being loosened; the
        // message is made true instead.
        status.value = 'in_review';
        showAlert(
            'Still reviewing',
            "We're checking your ID — this usually takes a few minutes. "
                "We'll let you know as soon as it's approved, and you can "
                "finish your booking then.",
            false);
        _finish(verified: false);
      }
    } catch (e) {
      status.value = 'error';
      showAlert('Error', e.toString().replaceAll('Exception: ', ''), true);
    } finally {
      busy.value = false;
    }
  }

  /// User chose "I'll do this later".
  void skipForNow() {
    _finish(verified: false);
  }

  Future<void> _finish({required bool verified}) async {
    // Refresh cached user so verification_status reflects on profile + gates.
    if (Get.isRegistered<AuthController>()) {
      try {
        await Get.find<AuthController>().getUserDetails(skipLogoutOnError: true);
      } catch (_) {}
    }
    if (isGuestContext || returnResult) {
      Get.back(result: verified); // back to the caller (e.g. booking screen)
      return;
    }
    Get.offAllNamed(isHost ? '/host/home' : '/home');
  }

  bool _isTerminal(String s) =>
      _isVerified(s) || s == 'declined' || s == 'in_review' || s == 'error';

  bool _isVerified(String s) => s == 'verified' || s == 'approved';
}
