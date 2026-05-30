import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:rent_home/constants.dart';

class InvoicePage extends StatelessWidget {
  InvoicePage({super.key});

  // Sample list of invoices
  final List<Map<String, dynamic>> invoices = [
    {
      'invoice_number': 'INV-2025-001',
      'date': 'June 10, 2025',
      'property_name': 'Cozy Villa Retreat',
      'guest_name': 'John Doe',
      'guest_email': 'john.doe@example.com',
      'guest_phone': '+91 98765 43210',
      'check_in': 'June 15, 2025',
      'check_out': 'June 22, 2025',
      'nightly_rate': 5000,
      'weekly_rate': 30000,
      'monthly_security': 10000,
      'cleaning_fee': 1000,
      'total': 36000,
    },
    {
      'invoice_number': 'INV-2025-002',
      'date': 'June 12, 2025',
      'property_name': 'Seaside Cottage',
      'guest_name': 'Jane Smith',
      'guest_email': 'jane.smith@example.com',
      'guest_phone': '+91 87654 32109',
      'check_in': 'June 20, 2025',
      'check_out': 'June 27, 2025',
      'nightly_rate': 4500,
      'weekly_rate': 28000,
      'monthly_security': 8000,
      'cleaning_fee': 800,
      'total': 33600,
    },
    {
      'invoice_number': 'INV-2025-003',
      'date': 'June 15, 2025',
      'property_name': 'Mountain Lodge',
      'guest_name': 'Alice Brown',
      'guest_email': 'alice.brown@example.com',
      'guest_phone': '+91 76543 21098',
      'check_in': 'June 25, 2025',
      'check_out': 'July 2, 2025',
      'nightly_rate': 6000,
      'weekly_rate': 35000,
      'monthly_security': 12000,
      'cleaning_fee': 1200,
      'total': 42200,
    },
  ];

  // Generate PDF for a specific invoice
  Future<String> _generatePdf(Map<String, dynamic> invoiceData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Invoice #${invoiceData['invoice_number']}',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Date: ${invoiceData['date']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 16),
            pw.Text('Property: ${invoiceData['property_name']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Guest: ${invoiceData['guest_name']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Email: ${invoiceData['guest_email']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Phone: ${invoiceData['guest_phone']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 24),
            pw.Text('Booking Details',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Check-in: ${invoiceData['check_in']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Check-out: ${invoiceData['check_out']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 24),
            pw.Text('Pricing',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Nightly Rate: ₹${invoiceData['nightly_rate']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Weekly Rate: ₹${invoiceData['weekly_rate']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Monthly Security: ₹${invoiceData['monthly_security']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Cleaning Fee: ₹${invoiceData['cleaning_fee']}',
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 16),
            pw.Text('Total: ₹${invoiceData['total']}',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    // Save the PDF to a temporary file
    final directory = await getTemporaryDirectory();
    final file =
        File('${directory.path}/invoice_${invoiceData['invoice_number']}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // Share the PDF for a specific invoice
  Future<void> _sharePdf(Map<String, dynamic> invoiceData) async {
    final pdfPath = await _generatePdf(invoiceData);
    await Share.shareXFiles([XFile(pdfPath)],
        text: 'Invoice for ${invoiceData['property_name']}');
  }

  // Download/Preview the PDF for a specific invoice
  Future<void> _downloadPdf(Map<String, dynamic> invoiceData) async {
    final pdfPath = await _generatePdf(invoiceData);
    await Printing.layoutPdf(
        onLayout: (format) async => File(pdfPath).readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Invoices'),
        backgroundColor: kprimaryColor,
        foregroundColor: kscaffoldColor,
        elevation: 2,
        //   leading: IconButton(
        //     icon: const Icon(Iconsax.arrow_left_2),
        //     onPressed: () => Get.back(),
        //   ),
        // ),
      ),
      body: invoices.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.document_1, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No invoices available',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // 👈 aligns nicely when multiline
                                children: [
                                  const Icon(Iconsax.document_text,
                                      color: kprimaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Invoice #${invoice['invoice_number']}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      softWrap: true, // 👈 allows wrapping
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Property: ${invoice['property_name']}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Guest: ${invoice['guest_name']}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Total: ₹${invoice['total']}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Iconsax.share,
                                  color: kprimaryColor, size: 24),
                              onPressed: () => _sharePdf(invoice),
                              tooltip: 'Share Invoice',
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.document_download,
                                  color: kprimaryColor, size: 24),
                              onPressed: () => _downloadPdf(invoice),
                              tooltip: 'Download Invoice',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
