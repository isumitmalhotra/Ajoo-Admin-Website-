import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/cancellation_policy.dart';
import 'package:rent_home/service/cancellation_policy_service.dart';
import 'package:rent_home/ui/screens_common/cancellation_policy/cancellation_policy_page.dart';
import 'package:rent_home/utils/fonts.dart';

/// The cancellation policy for THIS stay, as dates, with the acknowledgement
/// the guest must give before Book Now.
///
/// Policy v1.0 §15: before payment the guest must clearly see the policy, the
/// refund percentages, the important dates, a link to the full text — and
/// actively acknowledge it. The dates come from the server, worked out from
/// the property's policy and its check-in time in IST, by the engine that
/// will apply them; the app draws, it does not compute.
class StayCancellationCard extends StatefulWidget {
  const StayCancellationCard({
    super.key,
    required this.propertyId,
    required this.checkIn,
    required this.accepted,
    required this.onAccepted,
  });

  final int propertyId;
  final DateTime checkIn;
  final bool accepted;
  final ValueChanged<bool> onAccepted;

  @override
  State<StayCancellationCard> createState() => _StayCancellationCardState();
}

class _StayCancellationCardState extends State<StayCancellationCard> {
  CancellationSchedule? _schedule;
  bool _failed = false;
  String _loadedFor = '';

  String get _checkInKey => DateFormat('dd-MM-yyyy').format(widget.checkIn);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StayCancellationCard old) {
    super.didUpdateWidget(old);
    // A new check-in date is a new set of deadlines.
    if (_checkInKey != _loadedFor) _load();
  }

  /// Fetch the ladder, and do not give up on the first stumble.
  ///
  /// One dropped request used to leave "we couldn't load the refund dates"
  /// on screen for the rest of the session: nothing retried, and the only way
  /// back was to change the check-in date. Seen once on a stay whose dates the
  /// endpoint served correctly a moment later, which is exactly the shape of a
  /// transient failure.
  ///
  /// Three attempts, backing off, and the last word is left to the guest via
  /// the Try again control — because the alternative to showing these dates is
  /// asking somebody to accept terms they were never shown.
  Future<void> _load() async {
    final key = _checkInKey;
    _loadedFor = key;
    setState(() => _failed = false);

    const backoff = [Duration.zero, Duration(milliseconds: 400), Duration(milliseconds: 1200)];
    for (final wait in backoff) {
      if (wait > Duration.zero) await Future.delayed(wait);
      // The date changed under us; that request owns the card now.
      if (!mounted || key != _loadedFor) return;
      final s = await CancellationPolicyService.instance.schedule(widget.propertyId, key);
      if (!mounted || key != _loadedFor) return;
      if (s != null) {
        setState(() {
          _schedule = s;
          _failed = false;
        });
        return;
      }
    }

    setState(() {
      // The OLD ladder must go with it. Leaving it up would show one stay's
      // deadlines above another stay's dates.
      _schedule = null;
      _failed = true;
    });
    // An acknowledgement given for the previous dates does not carry over to
    // dates nobody has seen.
    if (widget.accepted) widget.onAccepted(false);
  }

  // The server's instants are UTC; the guest is told IST, which is what the
  // property's check-in time was in.
  static String _ist(DateTime utc) {
    final ist = utc.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('d MMM, h:mm a').format(ist);
  }

  void _openFullPolicy() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CancellationPolicyPage(scrollToPolicy: _schedule?.policy)),
      );

  @override
  Widget build(BuildContext context) {
    final s = _schedule;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.event_busy_outlined, size: 17, color: kprimaryColor),
            const SizedBox(width: 7),
            Text('Cancellation policy for this stay',
                style: inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
          ]),
          const SizedBox(height: 6),
          if (s == null)
            _failed
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "We couldn't load the refund dates for this stay, so we can't ask you to accept them yet.",
                        style: inter(fontSize: 12.5, color: kMuted, height: 1.45),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _load,
                        child: Text('Try again',
                            style: inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: kprimaryColor)
                                .copyWith(decoration: TextDecoration.underline)),
                      ),
                    ],
                  )
                : Text(
                    'Loading the refund dates for this stay…',
                    style: inter(fontSize: 12.5, color: kMuted, height: 1.45),
                  )
          else ...[
            RichText(
              text: TextSpan(
                style: inter(fontSize: 12.8, color: kMuted, height: 1.5),
                children: [
                  TextSpan(text: '${s.label}. ', style: inter(fontSize: 12.8, fontWeight: FontWeight.w700, color: kInk)),
                  TextSpan(text: s.summary),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (s.manualReview)
              Text(
                'This property is on business-approved terms — refunds follow its commercial agreement, confirmed by our team.',
                style: inter(fontSize: 12.5, color: kMuted, height: 1.45),
              )
            else ...[
              for (var i = 0; i < s.steps.length; i++) _step(s, i),
              _line('After check-in or no-show: no refund'),
            ],
            const SizedBox(height: 4),
            Text('Times are IST, measured from the property\'s check-in time (${s.checkInTime}).',
                style: inter(fontSize: 11.5, color: kMuted)),
          ],
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _openFullPolicy,
            child: Text('Read the full Cancellation & Refund Policy',
                style: inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kprimaryColor)
                    .copyWith(decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 2),
          // The acknowledgement. Book Now refuses until this is ticked — named
          // on the button's snackbar, so it is a step and not a dead button.
          //
          // Dead while the ladder is missing, on purpose. Policy v1.0 §15 asks
          // that the guest SEE the percentages and the dates before they accept
          // them; a tickable box above "we couldn't load the refund dates"
          // collects an acknowledgement of something nobody was shown. Try
          // again is the way forward, not a tick.
          InkWell(
            onTap: _failed ? null : () => widget.onAccepted(!widget.accepted),
            child: Opacity(
              opacity: _failed ? 0.45 : 1,
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: widget.accepted,
                  onChanged: _failed ? null : (v) => widget.onAccepted(v ?? false),
                  activeColor: kprimaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Text('I have read and accept the cancellation policy for this stay.',
                        style: inter(fontSize: 12.8, color: kInk, height: 1.4)),
                  ),
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(CancellationSchedule s, int i) {
    final st = s.steps[i];
    final prev = i > 0 ? s.steps[i - 1] : null;
    if (st.until != null) {
      return _line('${st.percent}% refund if you cancel by ${_ist(st.until!)}');
    }
    if (st.percent > 0) return _line('${st.percent}% refund after that, until check-in');
    return _line(prev?.until != null ? 'No refund after ${_ist(prev!.until!)}' : 'No refund after that');
  }

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: inter(fontSize: 12.5, color: kInk)),
            Expanded(child: Text(text, style: inter(fontSize: 12.5, color: kInk, height: 1.4))),
          ],
        ),
      );
}
