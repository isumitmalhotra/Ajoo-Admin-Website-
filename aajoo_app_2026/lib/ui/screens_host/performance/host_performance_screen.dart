import 'package:flutter/material.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/service/growth_service.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';

/// How a host's listings are actually doing — the mobile counterpart of the
/// web's /host/performance.
///
/// GET /host/performance/summary has existed since the finance sprint and the
/// app never read it, so the only numbers a host could see on the phone were
/// today's earnings. Occupancy, cancellations and the revenue trend were
/// web-only.
///
/// Every figure here is the server's. Where a comparison period does not exist
/// the change is omitted rather than printed as 0%, which would claim "no
/// change" when the truth is "nothing to compare against".
class HostPerformanceScreen extends StatefulWidget {
  const HostPerformanceScreen({super.key});

  @override
  State<HostPerformanceScreen> createState() => _HostPerformanceScreenState();
}

class _HostPerformanceScreenState extends State<HostPerformanceScreen> {
  HostPerformance? _p;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await GrowthService.instance.performance();
    if (!mounted) return;
    setState(() {
      _p = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: kSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kInk,
        titleSpacing: 0,
        title: Text('Performance',
            style:
                fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _p == null
              ? _unavailable()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    children: [
                      // The window the SERVER actually uses. /host/performance/
                      // summary compares the last 90 days against the 90
                      // before; this said "six months, against the six
                      // before", so every figure on the screen was labelled
                      // with a period twice as long as the one it covered.
                      // The website says "last 90 days" for the same numbers.
                      Text('Last 90 days, against the 90 before.',
                          style: inter(
                              fontSize: 13.5, color: kMuted, height: 1.4)),
                      const SizedBox(height: 16),
                      _metric('Revenue', rupees(_p!.revenue.current),
                          _p!.revenue, isMoney: true),
                      const SizedBox(height: 12),
                      _metric('Occupancy', '${_p!.occupancy.current.round()}%',
                          _p!.occupancy),
                      const SizedBox(height: 12),
                      _metric('Cancellations',
                          '${_p!.cancellations.current.round()}',
                          _p!.cancellations, lowerIsBetter: true),
                      const SizedBox(height: 12),
                      _metric(
                          'Average rating',
                          _p!.ratings.current <= 0
                              ? 'No ratings yet'
                              : _p!.ratings.current.toStringAsFixed(1),
                          _p!.ratings),
                      const SizedBox(height: 16),
                      if (_p!.channelSplit.isNotEmpty) _channels(_p!),
                    ],
                  ),
                ),
    );
  }

  Widget _unavailable() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insights_outlined, size: 48, color: kMuted),
              const SizedBox(height: 12),
              Text("Couldn't load your performance",
                  style: fraunces(
                      fontSize: 17, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 6),
              Text('Check your connection and pull down to try again.',
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 13.5, color: kMuted, height: 1.5)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );

  Widget _metric(
    String label,
    String value,
    PerfMetric m, {
    bool isMoney = false,
    bool lowerIsBetter = false,
  }) {
    final change = m.changePercent;
    // For cancellations a fall is good, so the colour follows meaning rather
    // than sign.
    final bool? good = change == null
        ? null
        : (lowerIsBetter ? change < 0 : change > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(),
                        style: inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kMuted,
                            letterSpacing: 1.1)),
                    const SizedBox(height: 6),
                    Text(value,
                        style: fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                  ],
                ),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: good == true
                        ? const Color(0xFFEAF6EE)
                        : const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                    style: inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: good == true ? kSuccess : kDanger),
                  ),
                ),
            ],
          ),
          if (m.trend.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Sparkline(values: m.trend),
          ],
          if (change == null) ...[
            const SizedBox(height: 8),
            // Said plainly, rather than showing a 0% that means something else.
            Text('No earlier period to compare against yet.',
                style: inter(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }

  Widget _channels(HostPerformance p) {
    const labels = ['Direct', 'App', 'Partner'];
    final total = p.channelSplit.fold<num>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where bookings came from',
              style: fraunces(
                  fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 12),
          if (total <= 0)
            Text('No bookings in this period.',
                style: inter(fontSize: 13, color: kMuted))
          else
            ...List.generate(p.channelSplit.length, (i) {
              final v = p.channelSplit[i];
              final pct = total <= 0 ? 0.0 : (v / total);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              i < labels.length ? labels[i] : 'Other',
                              style: inter(fontSize: 13, color: kInk)),
                        ),
                        Text('${v.round()}',
                            style: inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kInk)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: kLine,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(kIndigo),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// A small trend line. Deliberately unlabelled — it shows shape, and the number
/// above it is the fact.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});

  final List<num> values;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        width: double.infinity,
        child: CustomPaint(painter: _SparkPainter(values)),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values);

  final List<num> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce((a, b) => a > b ? a : b).toDouble();
    final minV = values.reduce((a, b) => a < b ? a : b).toDouble();
    // A flat series would divide by zero; draw it down the middle instead.
    final span = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y =
          size.height - ((values[i].toDouble() - minV) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()..color = kIndigo.withOpacity(0.10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = kIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values;
}
