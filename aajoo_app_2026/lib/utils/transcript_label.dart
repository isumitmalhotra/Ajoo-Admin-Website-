/// What to call one message in a negotiation thread.
///
/// A status describes what happened TO a message, not what its sender did —
/// whoever ACTS on an offer is always the other side from whoever SENT it. Read
/// the other way round, a renter whose offer the host had declined was shown
/// "You declined ₹650" on their own screen, at the end of the one thread that
/// needed to explain itself.
///
/// One rule, four screens: the website's guest and host negotiation pages
/// (src/redesign/lib/negotiationLabels.ts), the app's guest list, and the app's
/// host list. They drifted for a fortnight over whose move it was, by exactly
/// the route of each screen writing its own.
library;

/// Whose screen this is.
enum TranscriptViewer { guest, host }

/// @param mine       was this message sent by the person reading it
/// @param status     pending | countered | accepted | declined | expired
/// @param automatic  written by the platform in the host's name (host view)
String transcriptLabel({
  required bool mine,
  required String status,
  required TranscriptViewer viewer,
  bool automatic = false,
}) {
  final s = status.toLowerCase();
  final accepted = s == 'accepted';
  final declined = s == 'declined';
  final expired = s == 'expired';

  if (viewer == TranscriptViewer.host) {
    if (mine) {
      // The platform answers in the host's name — both when it quotes a
      // counter and when it takes an offer that already clears their target.
      // A host must be able to tell which words are theirs.
      if (automatic && accepted) return 'Accepted for you';
      if (accepted) return 'Your counter was accepted';
      if (declined) return 'Your counter was declined';
      return automatic ? 'Answered for you, at your price' : 'You countered';
    }
    if (accepted) return 'Accepted';
    if (declined) return 'Declined';
    return 'Guest offered';
  }

  if (mine) {
    if (accepted) return 'Your offer was accepted';
    if (declined) return 'Your offer was declined';
    if (expired) return 'Your offer expired';
    return 'You offered';
  }
  if (accepted) return 'Accepted';
  if (declined) return 'Declined';
  if (expired) return 'Expired';
  return 'Host countered';
}
