import 'package:flutter/material.dart';

/// Global ScaffoldMessenger key — wired into GetMaterialApp in main.dart.
/// Using ScaffoldMessenger (instead of Get.snackbar) avoids the
/// "No Overlay widget found" crash that GetX's snackbar throws when shown
/// during route transitions / before an overlay is ready.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAlert(String title, String message, bool isError) {
  // Best-effort, never throws. Deferred to the next frame so the messenger
  // is mounted, and guarded so a missing messenger silently no-ops instead
  // of crashing the calling flow.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    try {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: isError ? const Color(0xFFDC2626) : const Color(0xFF15803D),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor:
              isError ? const Color(0xFFFDECEA) : const Color(0xFFE8F1EC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // Never let a toast crash the calling flow.
    }
  });
}
