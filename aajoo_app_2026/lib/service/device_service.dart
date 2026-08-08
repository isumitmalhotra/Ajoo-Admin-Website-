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

  static void launchGoogleMaps(double latitude, double longitude) async {
    if (latitude.runtimeType != double || longitude.runtimeType != double) {
      throw 'Invalid latitude or longitude';
    }
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      throw 'Could not open Google Maps';
    }
  }

  static void launchWhatsapp({
    String? phoneNumber,
    String? message,
  }) async {
    // simply open whatsapp
    String whatsappUrl = 'https://wa.me/';
    if (phoneNumber != null) {
      whatsappUrl += "+91";
      whatsappUrl += phoneNumber;
    }
    if (message != null) {
      whatsappUrl += '?text=${Uri.encodeComponent(message)}';
    }
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      throw 'Could not open WhatsApp';
    }
  }

  static void _launchAppleMaps(double latitude, double longitude) async {
    final appleMapsUrl = 'https://maps.apple.com/?q=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
      await launchUrl(Uri.parse(appleMapsUrl));
    } else {
      throw 'Could not open Apple Maps';
    }
  }

  static void launchDialPad(String phoneNumber) async {
    final dialUrl = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(dialUrl))) {
      await launchUrl(Uri.parse(dialUrl));
    } else {
      throw 'Could not launch dial pad';
    }
  }

  void launchPhone(String userDetailsUserPnumber) async {
    final phoneUrl = 'tel:+91$userDetailsUserPnumber';
    if (await canLaunchUrl(Uri.parse(phoneUrl))) {
      launchUrl(Uri.parse(phoneUrl));
    } else {
      throw 'Could not launch phone dialer';
    }
  }
}
