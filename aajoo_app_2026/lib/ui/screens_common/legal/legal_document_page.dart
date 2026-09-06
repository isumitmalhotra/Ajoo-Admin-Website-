import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/legal_document.dart';
import 'package:rent_home/service/legal_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// A legal document, read from the server.
///
/// The Legal & Compliance suite says these documents must be available "from
/// the website footer, mobile app, and during user onboarding". The Host
/// Agreement had none of those. This is the app's copy of the website's
/// /host-agreement page — literally the same words, because both fetch the
/// same endpoint rather than each carrying a transcription.
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({
    super.key,
    this.documentKey = 'host_agreement',
    this.title = 'Host Agreement',
  });

  final String documentKey;
  final String title;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  LegalDocument? _doc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    LegalService.instance.document(widget.documentKey).then((d) {
      if (!mounted) return;
      setState(() {
        _doc = d;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        title: Text(doc?.title ?? widget.title,
            style: inter(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : doc == null
              // An empty screen is indistinguishable from "there is no
              // agreement", which is the impression this work exists to end.
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      "We couldn't load this document. Please check your "
                      "connection and try again.",
                      textAlign: TextAlign.center,
                      style: inter(fontSize: 13.5, color: kMuted, height: 1.6),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                  children: [
                    Text(
                      "Version ${doc.version} · effective ${doc.effectiveDate}",
                      style: inter(fontSize: 11.5, color: kMuted),
                    ),
                    const SizedBox(height: 6),
                    for (final s in doc.sections) ..._section(s),
                  ],
                ),
    );
  }

  List<Widget> _section(LegalSection s) {
    final out = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 7),
        child: Text(
          s.number > 0 ? "${s.number}. ${s.title}" : s.title,
          style: inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: kInk),
        ),
      ),
    ];
    for (final b in s.blocks) {
      if (b.type == 'p') {
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(b.text ?? '',
              style: inter(fontSize: 13, color: kMuted, height: 1.65)),
        ));
      } else {
        for (final li in b.items) {
          out.add(Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("•", style: inter(fontSize: 13, color: kMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(li,
                      style: inter(fontSize: 13, color: kMuted, height: 1.65)),
                ),
              ],
            ),
          ));
        }
      }
    }
    return out;
  }
}
