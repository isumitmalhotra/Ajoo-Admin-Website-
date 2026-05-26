import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialRow extends StatelessWidget {
  const SocialRow({super.key, this.rowAlignment = MainAxisAlignment.center});
  final MainAxisAlignment rowAlignment;

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _openFacebook() {
    const url = "https://www.facebook.com/AajooHomes/?rdid=Xk4MYAtu8puZO3Z8";
    _launchURL(url);
  }

  void _openX() {
    const url = "https://x.com/Aajoo_homes?t=HieggvtlaOe8ZyBNss0Ygg&s=08";
    _launchURL(url);
  }

  void _openInstagram() {
    const url = "https://www.instagram.com/aajoohomes_?igsh=aXh3ajhyNzBsOHV3";
    _launchURL(url);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: rowAlignment,
      children: [
        IconButton(
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "assets/facebook_logo.png",
                height: 30,
                width: 30,
              ),
            ),
            onPressed: _openFacebook),
        IconButton(
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "assets/x_logo.jpg",
                height: 30,
                width: 30,
              ),
            ),
            onPressed: _openX),
        IconButton(
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "assets/insta_logo.png",
                height: 30,
                width: 30,
              ),
            ),
            onPressed: _openInstagram),
      ],
    );
  }
}
