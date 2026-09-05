import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';

/// "Couldn't load" — shown INSTEAD of an empty state when the request failed.
///
/// An empty list and a failed request used to look identical: both drew the
/// screen's empty state. A host with seventeen notifications saw "No
/// notifications yet" because the call had failed, and nothing on screen said
/// so (APP #19). This is the other branch, with the one thing the empty state
/// cannot offer: a way to try again.
class LoadFailed extends StatelessWidget {
  const LoadFailed({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = "Couldn't load this",
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: kMuted),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: inter(
                    fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: inter(fontSize: 13.5, color: kMuted, height: 1.45)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try again',
                  style: inter(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo,
                side: const BorderSide(color: kIndigo),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
