import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialRow extends StatelessWidget {
  const SocialRow({super.key, this.rowAlignment = MainAxisAlignment.center});
  final MainAxisAlignment rowAlignment;

  // Canonical profile URLs, identical to the web's SOCIAL_LINKS.
  //
  // These used to carry the `?rdid=` / `?igsh=` / `?t=` share tokens that get
  // minted when you tap "Share profile" in the app you copied them from. They
  // are tracking parameters attached to one particular share, not part of the
  // address, and they are what made it non-obvious that the website was
  // pointing at three different (guessed) handles.
  static const _facebook = "https://www.facebook.com/AajooHomes/";
  static const _x = "https://x.com/Aajoo_homes";
  static const _instagram = "https://www.instagram.com/aajoohomes_/";

  /// Opens [url] in the browser, or in the platform's own app for that link.
  ///
  /// Was `canLaunch` / `launch` — the pre-6.x API, and the only place in the
  /// app still on it. Two things were wrong with that:
  ///
  ///   * `canLaunch` resolves against the installed-app list Android 11 hid,
  ///     so without the package-visibility `<queries>` the manifest did not
  ///     declare it answered false for https, and these three icons did
  ///     nothing at all on any recent device.
  ///   * the else branch threw a bare String out of an `async void`, where
  ///     nothing could catch it — an unhandled exception rather than feedback.
  ///
  /// The manifest now declares the schemes. This launches directly and reports
  /// failure to the guest: `launchUrl` was never the gated call, so attempting
  /// it and handling a false return is both simpler and more robust than
  /// asking permission first.
  Future<void> _launchURL(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger?.showSnackBar(
        const SnackBar(content: Text("Couldn't open that link.")),
      );
    }
  }

  Widget _icon(BuildContext context, String asset, String url, String label) {
    return IconButton(
      tooltip: label,
      icon: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(asset, height: 30, width: 30),
      ),
      onPressed: () => _launchURL(context, url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: rowAlignment,
      children: [
        _icon(context, "assets/facebook_logo.png", _facebook, "Facebook"),
        _icon(context, "assets/x_logo.jpg", _x, "X"),
        _icon(context, "assets/insta_logo.png", _instagram, "Instagram"),
      ],
    );
  }
}
