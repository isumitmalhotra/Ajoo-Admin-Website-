import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/money.dart';

/// A host's monthly statements.
///
/// `/host/statements/search` and `/host/statements/download/:id` shipped with
/// the finance sprint and NEITHER client called them: on the web
/// `/host/statements` redirected to Payouts, and the app had no reader at all.
/// So a host could not open a statement or download one, on either platform.
///
/// A statement is a MONTH. It shows what was earned, what the platform took as
/// commission, and what was actually paid out — the commission column matters,
/// because a statement showing only a net figure cannot be checked.
class HostStatementsScreen extends StatefulWidget {
  const HostStatementsScreen({super.key});

  @override
  State<HostStatementsScreen> createState() => _HostStatementsScreenState();
}

class _HostStatementsScreenState extends State<HostStatementsScreen> {
  final HostService _service = HostService();
  final RxBool loading = true.obs;
  final RxList<Map<String, dynamic>> rows = <Map<String, dynamic>>[].obs;
  final RxnString busyId = RxnString();

  @override
  void initState() {
    super.initState();
    // After the first frame — flipping an observable during build throws
    // "setState() called during build" and the screen spins forever.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      rows.value = await _service.getStatements();
    } finally {
      loading.value = false;
    }
  }

  static double _n(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  /// Indian grouping lives in utils/money.dart — one rule for the product.
  static String _inr(num v) => rupees(v);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  /// "2026-08" -> "August 2026". Falls back to the raw key if it is not a period.
  static String _pretty(String p) {
    final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(p);
    if (m == null) return p.isEmpty ? '—' : p;
    final mi = int.tryParse(m.group(2)!) ?? 0;
    return '${mi >= 1 && mi <= 12 ? _months[mi - 1] : m.group(2)} ${m.group(1)}';
  }

  Future<void> _download(String id) async {
    busyId.value = id;
    try {
      final bytes = await _service.downloadStatement(id);
      if (!mounted) return;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("That statement couldn't be downloaded."),
          backgroundColor: kDanger,
        ));
        return;
      }
      // Hands the PDF to the OS print/share sheet, the same way the Invoices
      // screen already does, so "download" behaves consistently in the app.
      await Printing.layoutPdf(
          onLayout: (_) async => Uint8List.fromList(bytes));
    } finally {
      busyId.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        title: Text('Statements',
            style:
                inter(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
      ),
      body: Obx(() {
        if (loading.value && rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rows.isEmpty) {
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.receipt_long_outlined,
                    size: 34, color: kMuted),
                const SizedBox(height: 10),
                Text('No statements yet',
                    textAlign: TextAlign.center,
                    style: inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
                const SizedBox(height: 6),
                Text(
                  'A statement is produced for each month you earn in. Once a stay is paid for, its month appears here.',
                  textAlign: TextAlign.center,
                  style: inter(fontSize: 13, color: kMuted, height: 1.5),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final r = rows[i];
              final id = '${r['statement_id'] ?? r['period'] ?? ''}';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_pretty('${r['period'] ?? id}'),
                        style: inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: kInk)),
                    const SizedBox(height: 10),
                    _line('Earnings', _inr(_n(r['totalEarnings'])), bold: true),
                    _line('Platform commission',
                        _inr(_n(r['totalCommission']))),
                    _line('Paid out', _inr(_n(r['totalPayouts']))),
                    _line('Invoices', '${_n(r['invoiceCount']).round()}'),
                    const SizedBox(height: 10),
                    Obx(() => SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                busyId.value == id ? null : () => _download(id),
                            icon: const Icon(Icons.download_rounded, size: 17),
                            label: Text(
                                busyId.value == id
                                    ? 'Preparing…'
                                    : 'Download statement',
                                style: inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kIndigo,
                              side: const BorderSide(color: kIndigo),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11)),
                            ),
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _line(String l, String r, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: inter(fontSize: 12.5, color: kMuted)),
            Text(r,
                style: inter(
                    fontSize: bold ? 14.5 : 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: kInk)),
          ],
        ),
      );
}
