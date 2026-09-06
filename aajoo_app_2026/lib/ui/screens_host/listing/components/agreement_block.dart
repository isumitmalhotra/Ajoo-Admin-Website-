import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/legal_document.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

/// The Host Agreement, on step 5.
///
/// Developer Requirement 1: "Require Hosts to scroll through the Host
/// Agreement before publishing their first property." So the text is here, in
/// a scrollable box, and the checkbox under it stays disabled until the host
/// reaches the end. Requirement 2: one checkbox, in the agreement's own
/// wording, naming all four documents — served by the API rather than retyped,
/// so the app and the website ask for the same consent.
///
/// What this replaces: a checkbox labelled "I accept the Host Agreement", for
/// an agreement that existed nowhere on the platform, storing a boolean.
class HostAgreementBlock extends StatelessWidget {
  const HostAgreementBlock({super.key, required this.c});

  final ListingWizardController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.agreementDone.value) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_rounded, size: 18, color: kSuccess),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                c.agreement.value == null
                    ? "You've accepted the Host Agreement."
                    : "You've accepted the Host Agreement "
                        "(version ${c.agreement.value!.version}).",
                style: inter(fontSize: 13.5, color: kInk, height: 1.5),
              ),
            ),
          ],
        );
      }

      final doc = c.agreement.value;
      if (doc == null) {
        // Not an error banner: the agreement is fetched at init and the host
        // may simply have arrived first. The submit button stays disabled
        // either way, and the server refuses regardless.
        return Text(
          "Loading the agreement… you will be asked to read and accept it "
          "before publishing.",
          style: inter(fontSize: 13, color: kMuted, height: 1.5),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Version ${doc.version} · effective ${doc.effectiveDate}",
            style: inter(fontSize: 11.5, color: kMuted),
          ),
          const SizedBox(height: 10),
          _ScrollToRead(
            onRead: () => c.agreementRead.value = true,
            child: _LegalBody(doc: doc),
          ),
          const SizedBox(height: 8),
          Text(
            c.agreementRead.value
                ? "You've reached the end of the agreement."
                : "Scroll to the end of the agreement to continue.",
            style: inter(
              fontSize: 11.5,
              color: c.agreementRead.value ? kSuccess : kMuted,
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: c.agreementRead.value ? 1 : 0.55,
            child: InkWell(
              onTap: c.agreementRead.value && !c.agreementBusy.value
                  ? c.acceptAgreement
                  : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: false,
                        onChanged:
                            c.agreementRead.value && !c.agreementBusy.value
                                ? (_) => c.acceptAgreement()
                                : null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        doc.acceptanceStatement,
                        style: inter(fontSize: 13, color: kInk, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (c.agreementBusy.value)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("Recording your acceptance…",
                  style: inter(fontSize: 11.5, color: kMuted)),
            ),
          if (c.agreementError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(c.agreementError.value,
                  style: inter(fontSize: 11.5, color: kDanger)),
            ),
        ],
      );
    });
  }
}

/// The document, in reading order.
class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.doc});
  final LegalDocument doc;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final s in doc.sections) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          s.number > 0 ? "${s.number}. ${s.title}" : s.title,
          style: inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk),
        ),
      ));
      for (final b in s.blocks) {
        if (b.type == 'p') {
          children.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(b.text ?? '',
                style: inter(fontSize: 12.5, color: kMuted, height: 1.6)),
          ));
        } else {
          for (final li in b.items) {
            children.add(Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("•", style: inter(fontSize: 12.5, color: kMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(li,
                        style:
                            inter(fontSize: 12.5, color: kMuted, height: 1.6)),
                  ),
                ],
              ),
            ));
          }
        }
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

/// A scroll box that reports when its content has been read to the end.
///
/// Two details make it honest rather than theatrical:
///
///   * a document SHORTER than the box counts as read the moment it lays out,
///     or the gate could never open and the host would be stuck forever;
///   * a two-pixel tolerance, because a fractional extent can leave the last
///     pixel unreachable on some densities — the classic version of this
///     control that people report as "I scrolled to the end and it still will
///     not let me continue".
class _ScrollToRead extends StatefulWidget {
  const _ScrollToRead({required this.child, required this.onRead});
  final Widget child;
  final VoidCallback onRead;

  @override
  State<_ScrollToRead> createState() => _ScrollToReadState();
}

class _ScrollToReadState extends State<_ScrollToRead> {
  final _ctrl = ScrollController();
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_fired || !_ctrl.hasClients) return;
    final p = _ctrl.position;
    // maxScrollExtent is 0 when everything already fits.
    if (p.maxScrollExtent <= 0 || p.pixels >= p.maxScrollExtent - 2) {
      _fired = true;
      widget.onRead();
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Scrollbar(
        controller: _ctrl,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _ctrl,
          padding: const EdgeInsets.only(bottom: 12),
          child: widget.child,
        ),
      ),
    );
  }
}
