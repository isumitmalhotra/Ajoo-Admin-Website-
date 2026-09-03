import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rent_home/constants.dart';

/// Collects the one-time email code that guards a sensitive change (a new
/// phone number, a password change).
///
/// The caller has ALREADY asked the server to email a code before opening
/// this sheet — the sheet only collects it. Verification happens server-side
/// when the caller submits the change with the code attached, so there is no
/// verify round-trip here; a wrong code surfaces as the save failing, and the
/// user can try again.
///
/// Returns the 6-digit code, or null when the user backs out — in which case
/// the caller must abandon the change entirely.
Future<String?> showEmailOtpSheet({
  required String email,
  required String title,
  required Future<({bool success, String message})> Function() resend,
}) {
  return Get.bottomSheet<String>(
    _EmailOtpSheet(email: email, title: title, resend: resend),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Tapping outside must count as backing out, not as approval — the
    // default dismiss returns null, which callers treat as "abort".
  );
}

class _EmailOtpSheet extends StatefulWidget {
  final String email;
  final String title;
  final Future<({bool success, String message})> Function() resend;

  const _EmailOtpSheet({
    required this.email,
    required this.title,
    required this.resend,
  });

  @override
  State<_EmailOtpSheet> createState() => _EmailOtpSheetState();
}

class _EmailOtpSheetState extends State<_EmailOtpSheet> {
  String _otp = '';
  bool _resending = false;
  // Same 30s cadence as the forgot-password screen — the mail genuinely takes
  // a few seconds to arrive, and hammering resend just queues duplicates.
  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final r = await widget.resend();
    if (!mounted) return;
    setState(() => _resending = false);
    Get.snackbar(
      r.success ? 'Code sent' : 'Error',
      r.message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: r.success ? Colors.green[50] : Colors.red[50],
      colorText: r.success ? Colors.green[900] : Colors.red[900],
    );
    if (r.success) _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    // How much room this sheet may actually occupy.
    //
    // The code field autofocuses, so the keyboard is up before the host has
    // done anything, and the sheet used to size itself to CONTENT PLUS the
    // keyboard inset with nothing capping it. Together those exceeded the
    // screen: the sheet ran off the top — its title sat 108px down, under the
    // status bar — and the Cancel / Resend row was pushed past the bottom of
    // its own background, where it painted as ghost text over the dimmed page
    // behind. Worse than untidy: a widget outside its parent's bounds is not
    // hit-tested, so Cancel took three taps and did nothing (APP #5). The only
    // way out was the system Back button.
    //
    // Capped at the room genuinely left, and the content scrolls if it still
    // does not fit — a short screen or a large font must not put the button
    // somewhere it cannot be pressed.
    // Never under the status bar, and never taller than the room on offer.
    final maxSheetHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top - 12;

    return LayoutBuilder(builder: (context, constraints) {
      // Reserve only the part of the keyboard the ROUTE has not already
      // reserved — this was the whole of APP #5.
      //
      // Measured on device: with the keypad up, the box handed to this sheet
      // was y 0..1848 on a 2856-tall screen. The keyboard was already out of
      // it. Subtracting viewInsets.bottom on top of that counted the keyboard
      // TWICE, squeezing an 880px panel into 840px, pinned to the top of the
      // screen with a 1000px gap of dimmed page below it. The title landed
      // under the status bar and the Cancel / Resend row was pushed out of
      // the panel's own background, where it painted as ghost text over the
      // page behind — and, being outside its parent's bounds, was not
      // hit-tested at all: Cancel took three taps and did nothing, leaving
      // the system Back button as the only way out.
      //
      // Padding by the shortfall is correct whichever way the route behaves:
      // nothing when it has already excluded the keyboard, the full inset
      // when it has handed over the whole screen.
      final alreadyReserved = media.size.height - constraints.maxHeight;
      final keyboardShortfall = (media.viewInsets.bottom - alreadyReserved)
          .clamp(0.0, double.infinity);

      return Align(
        // A bottom sheet belongs at the bottom of the room it is given.
        alignment: Alignment.bottomCenter,
        child: Padding(
          // Ride above the keyboard — a code entry the keyboard covers is
          // uncompletable.
          padding: EdgeInsets.only(bottom: keyboardShortfall),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Container(
              decoration: const BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kLine,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kInk),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We emailed a 6-digit code to ${widget.email}. '
                        'Enter it below to confirm this change.',
                        style: const TextStyle(fontSize: 13, color: kMuted),
                      ),
                      const SizedBox(height: 20),
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        autoFocus: true,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 48,
                          fieldWidth: 44,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.grey[50],
                          selectedFillColor: Colors.white,
                          activeColor: theme.primaryColor,
                          inactiveColor: Colors.grey[300]!,
                          selectedColor: theme.primaryColor,
                          borderWidth: 1.5,
                        ),
                        cursorColor: theme.primaryColor,
                        enableActiveFill: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        // An OTP paste is only ever six digits.
                        beforeTextPaste: (text) =>
                            RegExp(r'^\d{6}$').hasMatch((text ?? '').trim()),
                        onChanged: (value) => setState(() => _otp = value),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _otp.length == 6
                              ? () => Get.back(result: _otp)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kIndigo,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: kMuted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Confirm',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel',
                                style: TextStyle(color: kMuted)),
                          ),
                          TextButton(
                            onPressed: (_resending || _resendCountdown > 0)
                                ? null
                                : _resend,
                            child: Text(
                              _resendCountdown > 0
                                  ? 'Resend code in ${_resendCountdown}s'
                                  : _resending
                                      ? 'Sending…'
                                      : 'Resend code',
                              style: TextStyle(
                                color: _resendCountdown > 0 || _resending
                                    ? kMuted
                                    : kIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
