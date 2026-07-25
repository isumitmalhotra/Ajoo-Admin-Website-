import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/data/models/transaction_model.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';

/// Invoices — now wired to real host transactions (`getHostTransactions`).
/// Each successful payment is an invoice; share / download build the PDF from
/// the real transaction data. (Previously showed hardcoded sample invoices.)
class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late final HostController _hostController;

  @override
  void initState() {
    super.initState();
    _hostController = Get.isRegistered<HostController>()
        ? Get.find<HostController>()
        : Get.put(HostController());
    _hostController.getTransactionHistory();
  }

  Future<String> _generatePdf(Transaction t) async {
    final pdf = pw.Document();
    final date = DateFormat('MMM dd, yyyy').format(t.payAddedAt);
    pw.Widget row(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text('$label: $value',
              style: const pw.TextStyle(fontSize: 14)),
        );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice #${t.payInvoice}',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            row('Date', date),
            row('Property', t.paymentPropertyPropertyName),
            row('Guest', t.userPaymentUserFullName),
            pw.SizedBox(height: 20),
            pw.Text('Payment',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            row('Reference', t.payRazId),
            row('Status', t.paymentStatusBsTitle),
            pw.SizedBox(height: 16),
            pw.Text('Total: ₹${t.payAmount}',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/invoice_${t.payInvoice}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<void> _sharePdf(Transaction t) async {
    final pdfPath = await _generatePdf(t);
    await Share.shareXFiles([XFile(pdfPath)],
        text: 'Invoice for ${t.paymentPropertyPropertyName}');
  }

  Future<void> _downloadPdf(Transaction t) async {
    final pdfPath = await _generatePdf(t);
    await Printing.layoutPdf(
        onLayout: (format) async => File(pdfPath).readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Invoices',
            style: fraunces(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: kIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final loading = _hostController.loading.value &&
            _hostController.transactionHistoryResponse.value == null;
        if (loading) {
          return const Center(child: CircularProgressIndicator(color: kIndigo));
        }
        final txns = _hostController.transactionHistoryResponse.value?.data ??
            const <Transaction>[];
        return RefreshIndicator(
          color: kIndigo,
          onRefresh: () => _hostController.getTransactionHistory(),
          child: txns.isEmpty
              ? _empty()
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: txns.length,
                  itemBuilder: (context, index) => _invoiceCard(txns[index]),
                ),
        );
      }),
    );
  }

  Widget _empty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Iconsax.document_1, size: 60, color: kLine),
        const SizedBox(height: 14),
        Center(
          child: Text('No invoices yet',
              style: fraunces(
                  fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('Invoices appear here after guests pay for a stay.',
              textAlign: TextAlign.center,
              style: inter(fontSize: 13, color: kMuted)),
        ),
      ],
    );
  }

  Widget _invoiceCard(Transaction t) {
    final date = DateFormat('MMM dd, yyyy').format(t.payAddedAt);
    final paid = t.paymentStatusBsTitle.toLowerCase().contains('paid') ||
        t.paymentStatusBsTitle.toLowerCase().contains('success') ||
        t.paymentStatusBsTitle.toLowerCase().contains('complet');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Iconsax.document_text,
                        color: kIndigo, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Invoice #${t.payInvoice}',
                          style: fraunces(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: paid
                              ? const Color(0xFFEAF6EE)
                              : const Color(0xFFFFF1E6),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(t.paymentStatusBsTitle.trim(),
                          style: inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: paid ? kSuccess : kClay)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t.paymentPropertyPropertyName,
                    style: inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kInk2)),
                Text('Guest · ${t.userPaymentUserFullName}',
                    style: inter(fontSize: 12.5, color: kMuted)),
                Text(date, style: inter(fontSize: 12, color: kMuted)),
                const SizedBox(height: 6),
                Text('₹${t.payAmount}',
                    style: fraunces(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kIndigo600)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Iconsax.share, color: kIndigo, size: 22),
                onPressed: () => _sharePdf(t),
                tooltip: 'Share Invoice',
              ),
              IconButton(
                icon: const Icon(Iconsax.document_download,
                    color: kIndigo, size: 22),
                onPressed: () => _downloadPdf(t),
                tooltip: 'Download Invoice',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
