import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'kyc_controller.dart';

/// DIDIT identity-verification step. Shown after OTP at signup (renter_kyc /
/// host_kyc) and can be reused for booking-time guest_kyc.
///
/// Route args: { context: 'renter_kyc'|'host_kyc'|'guest_kyc', isHost: bool,
///               bookingId: int? }
class DiditKycScreen extends StatelessWidget {
  const DiditKycScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments ?? {}) as Map;
    final c = Get.put(KycController(
      context: (args['context'] ?? 'renter_kyc').toString(),
      isHost: args['isHost'] == true,
      bookingId: args['bookingId'] is int ? args['bookingId'] as int : null,
      returnResult: args['returnResult'] == true,
    ));

    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: kSand,
        elevation: 0,
        foregroundColor: kInk,
        title: const Text('Identity verification'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Obx(() {
            final busy = c.busy.value;
            final st = c.status.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kIndigo.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      size: 36, color: kIndigo),
                ),
                const SizedBox(height: 18),
                Text(
                  st == 'declined' ? 'Verification failed' : 'Verify your identity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: kInk),
                ),
                const SizedBox(height: 10),
                Text(
                  _subtitle(st, c.isGuestContext),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.5, color: kInk2, height: 1.4),
                ),
                const SizedBox(height: 28),

                if (busy) ...[
                  const Center(child: CircularProgressIndicator(color: kIndigo)),
                  const SizedBox(height: 12),
                  Text(
                    st == 'polling' ? 'Confirming your verification…' : 'Please wait…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kInk2),
                  ),
                ] else if (st == 'launched') ...[
                  // User has been sent to the browser; offer to confirm on return.
                  _primaryButton(
                    label: "I've finished verifying",
                    onTap: c.pollDecision,
                  ),
                  const SizedBox(height: 10),
                  _secondaryButton(
                    label: 'Reopen verification',
                    onTap: c.startVerification,
                  ),
                ] else if (st == 'declined') ...[
                  _primaryButton(label: 'Try again', onTap: c.startVerification),
                ] else ...[
                  _primaryButton(
                    label: 'Verify identity now',
                    onTap: c.startVerification,
                  ),
                ],

                const Spacer(),
                if (!busy)
                  TextButton(
                    onPressed: c.skipForNow,
                    child: Text(
                      c.isGuestContext ? 'Cancel' : "I'll do this later",
                      style: const TextStyle(
                          color: kInk2, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _subtitle(String st, bool guest) {
    switch (st) {
      case 'launched':
        return "Complete the secure ID + face check in the browser that just opened. "
            "When you're done, come back and tap the button below.";
      case 'declined':
        return "We couldn't verify your identity. You can try the verification again.";
      default:
        return guest
            ? 'A quick, secure ID + face check is required to confirm this booking.'
            : 'One quick, secure step — verify your identity (ID + face) so your '
                'bookings stay instant later, with no checks at checkout.';
    }
  }

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kClay,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _secondaryButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: kIndigo,
          side: const BorderSide(color: kIndigo),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
