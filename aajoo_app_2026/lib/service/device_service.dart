import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class DeviceService {
  static void showMapOptions(
      BuildContext context, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Open Location In'),
          content: SingleChildScrollView(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Image(
                    height: 30,
                    width: 30,
                    image: AssetImage('assets/google_maps.png'),
                  ),
                  title: const Text('Open in Google Maps'),
                  onTap: () {
                    launchGoogleMaps(latitude, longitude);
                    Navigator.pop(context);
                  },
                ),
                if (Platform.isIOS)
                  ListTile(
                    leading: const Image(
                      height: 30,
                      width: 30,
                      image: AssetImage('assets/apple_maps.png'),
                    ),
                    title: const Text('Open in Apple Maps'),
                    onTap: () {
                      _launchAppleMaps(latitude, longitude);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Hands [url] to the app that owns it, returning false instead of throwing.
  ///
  /// Every launcher below used to be `if (await canLaunchUrl(u)) launchUrl(u);
  /// else throw '...';`, which had two faults on Android 11+:
  ///
  ///   * `canLaunchUrl` resolves against the installed-app list Android 11
  ///     hid, so without the manifest `<queries>` it returned false and the
  ///     whole branch was skipped — WhatsApp support, tap-to-dial and Get
  ///     Directions all silently did nothing.
  ///   * the else threw a bare String from an `async void`, so when it did
  ///     fire nothing could catch it.
  ///
  /// The other half of the bug is the launch mode. `launchUrl` defaults to
  /// `platformDefault`, which on Android opens https in an in-app Custom Tab
  /// — so `wa.me` rendered WhatsApp's *web page* inside the app instead of
  /// handing off to WhatsApp, and the maps links opened a map web page rather
  /// than the Maps app. `externalApplication` is what makes the hand-off the
  /// deep links were chosen for actually happen.
  static Future<bool> _open(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> launchGoogleMaps(double latitude, double longitude) {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    return _open(googleMapsUrl);
  }

  static Future<bool> launchWhatsapp({
    String? phoneNumber,
    String? message,
  }) {
    // simply open whatsapp
    String whatsappUrl = 'https://wa.me/';
    if (phoneNumber != null) {
      whatsappUrl += "+91";
      whatsappUrl += phoneNumber;
    }
    if (message != null) {
      whatsappUrl += '?text=${Uri.encodeComponent(message)}';
    }
    return _open(whatsappUrl);
  }

  // ignore: unused_element
  static Future<bool> _launchAppleMaps(double latitude, double longitude) {
    return _open('https://maps.apple.com/?q=$latitude,$longitude');
  }

  static Future<bool> launchDialPad(String phoneNumber) {
    return _open('tel:$phoneNumber');
  }

  Future<bool> launchPhone(String userDetailsUserPnumber) {
    return _open('tel:+91$userDetailsUserPnumber');
  }
}
