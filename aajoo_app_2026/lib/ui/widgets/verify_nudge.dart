// A one-line prompt at the top of a dashboard for an account that has not been
// through the identity check.
//
// Hosts reported finding out they were unverified only at the moment it
// stopped them — a guest at checkout, a host pressing Publish after filling in
// five steps of a listing. Nothing anywhere said so beforehand, and the state
// is invisible until it blocks you. This says it on the first screen after
// signing in, where there is time to deal with it.
//
// Mirrors the web's VerifyNudge, down to the wording, so the two platforms
// don't describe the same state differently. Renders nothing for a verified
// account, and nothing while the profile is still loading — otherwise a
// verified host sees it flash on every dashboard build.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
// The AuthController that InitBinding actually registers. There are two
// classes with this name in the tree — the other one, lib/controller/, is
// never put into GetX, so Get.find<AuthController>() against it compiles
// cleanly and throws at runtime.
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/utils/fonts.dart';

class VerifyNudge extends StatelessWidget {
  const VerifyNudge({super.key, required this.isHost});

  /// Which side of the app is showing it — decides the KYC context the
  /// verification screen is opened with.
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Obx(() {
      final user = auth.userData.value;
      if (user == null) return const SizedBox.shrink();

      final status = user.verificationStatus.toLowerCase();
      if (status == 'verified') return const SizedBox.shrink();

      final ({String title, String body, String cta}) copy = switch (status) {
        'pending' => (
            title: "Your identity check wasn't finished",
            body: 'You started one but didn\'t complete it. '
                'Pick it up where you left off.',
            cta: 'Finish',
          ),
        'declined' => (
            title: 'Your identity check was declined',
            body: 'Something on the document didn\'t match. '
                'Try again with a clearer photo.',
            cta: 'Try again',
          ),
        'in_review' => (
            title: 'Your identity check is being reviewed',
            body: "We're taking a closer look. "
                "You'll hear from us as soon as it's decided.",
            cta: 'View',
          ),
        _ => (
            title: 'Verify your identity',
            body: "One check, about two minutes, and it's done for good. "
                "You'll need it before a booking is confirmed.",
            cta: 'Verify',
          ),
      };
      final isBad = status == 'declined';

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isBad ? kDanger.withOpacity(0.06) : kSand,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isBad ? kDanger : kLine),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isBad ? Icons.gpp_maybe_outlined : Icons.verified_user_outlined,
              color: isBad ? kDanger : kIndigo,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.title,
                    style: inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kInk),
                  ),
                  const SizedBox(height: 2),
                  Text(copy.body,
                      style: inter(fontSize: 12.5, color: kMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Get.toNamed('/kyc', arguments: {
                'context': isHost ? 'host_kyc' : 'renter_kyc',
                'isHost': isHost,
                'returnResult': true,
              }),
              child: Text(copy.cta,
                  style: inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kIndigo)),
            ),
          ],
        ),
      );
    });
  }
}
