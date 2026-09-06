import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/legal_document.dart';
import 'package:rent_home/service/legal_service.dart';
import 'package:rent_home/utils/fonts.dart';

/// Requirement 4 of the Host Agreement's Developer Requirements:
///
///   "Require Hosts to re-accept the Agreement whenever a material update is
///    published before they can continue using Host features."
///
/// So this is shown on entering the host portal, not tucked inside a settings
/// screen. It blocks ONLY a re-acceptance: a host who has simply never
/// accepted is asked at the publish step, which is where the Agreement puts
/// that requirement — walling a brand-new host out of a dashboard they have
/// not used yet is stricter than the document, and reads as a broken sign-in.
///
/// Fails OPEN. `LegalService.outstanding()` returns an empty list on any
/// error, so a question we could not ask can never lock a host out. The gate
/// that cannot be bypassed is the server's, on publish, and it fails closed.
Future<void> maybeShowAgreementGate(BuildContext context) async {
  final owed = await LegalService.instance.outstanding();
  final blocking = owed.where((d) => d.previouslyAccepted).toList();
  if (blocking.isEmpty) return;
  if (!context.mounted) return;

  for (final item in blocking) {
    final doc = await LegalService.instance.document(item.key);
    if (!context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AgreementDialog(item: item, doc: doc),
    );
    // Declined or dismissed by the system: stop asking for this session
    // rather than looping a dialog they cannot escape.
    if (accepted != true) return;
  }
}

class _AgreementDialog extends StatefulWidget {
  const _AgreementDialog({required this.item, required this.doc});
  final OutstandingLegal item;
  final LegalDocument? doc;

  @override
  State<_AgreementDialog> createState() => _AgreementDialogState();
}

class _AgreementDialogState extends State<_AgreementDialog> {
  final _ctrl = ScrollController();
  bool _read = false;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_read || !_ctrl.hasClients) return;
    final p = _ctrl.position;
    if (p.maxScrollExtent <= 0 || p.pixels >= p.maxScrollExtent - 2) {
      setState(() => _read = true);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() { _busy = true; _error = ''; });
    final problem = await LegalService.instance
        .accept(widget.item.key, context: 'reacceptance');
    if (!mounted) return;
    setState(() => _busy = false);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    return PopScope(
      // Not dismissible with Back: it is a gate, and one you can swipe past
      // is decoration. Sign out is the way through without accepting.
      canPop: false,
      child: AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        title: Text(
          "${widget.item.title} — version ${widget.item.version}",
          style: inter(fontSize: 16, fontWeight: FontWeight.w700, color: kInk),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We've updated this agreement (effective ${widget.item.effectiveDate}). "
                "Please read it and accept before continuing to use your host account.",
                style: inter(fontSize: 12.5, color: kMuted, height: 1.55),
              ),
              const SizedBox(height: 12),
              if (doc == null)
                Text("Loading the agreement…",
                    style: inter(fontSize: 12.5, color: kMuted))
              else ...[
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kLine),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Scrollbar(
                    controller: _ctrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _ctrl,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _sections(doc),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _read
                      ? "You've reached the end of the agreement."
                      : "Scroll to the end to continue.",
                  style: inter(
                      fontSize: 11.5, color: _read ? kSuccess : kMuted),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: _read ? 1 : 0.55,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: false,
                          onChanged:
                              _read && !_busy ? (_) => _accept() : null,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(doc.acceptanceStatement,
                            style: inter(
                                fontSize: 12.5, color: kInk, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
              if (_busy)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Recording your acceptance…",
                      style: inter(fontSize: 11.5, color: kMuted)),
                ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error,
                      style: inter(fontSize: 11.5, color: kDanger)),
                ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        actions: [
          // A gate with no way out is a trap. Not accepting is allowed; it
          // just leaves the host unable to publish, which the server enforces.
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text("Not now",
                style: inter(fontSize: 13, color: kMuted)),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(LegalDocument doc) {
    final out = <Widget>[];
    for (final s in doc.sections) {
      out.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 5),
        child: Text(
          s.number > 0 ? "${s.number}. ${s.title}" : s.title,
          style: inter(fontSize: 13, fontWeight: FontWeight.w700, color: kInk),
        ),
      ));
      for (final b in s.blocks) {
        if (b.type == 'p') {
          out.add(Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(b.text ?? '',
                style: inter(fontSize: 12, color: kMuted, height: 1.6)),
          ));
        } else {
          for (final li in b.items) {
            out.add(Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("•", style: inter(fontSize: 12, color: kMuted)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(li,
                        style: inter(fontSize: 12, color: kMuted, height: 1.6)),
                  ),
                ],
              ),
            ));
          }
        }
      }
    }
    return out;
  }
}
