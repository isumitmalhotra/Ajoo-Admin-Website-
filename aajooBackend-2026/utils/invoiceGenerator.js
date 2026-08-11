const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

/**
 * Generates a simple invoice PDF and returns the file path.
 * @param {Object} invoiceData - Data for the invoice.
 * @param {string} outputDir - Directory to save the PDF.
 * @returns {Promise<string>} - Path to the generated PDF file.
 */
async function generateInvoicePDF(invoiceData, outputDir = './uploads/invoices') {
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  const fileName = `invoice_${invoiceData.booking_id}_${Date.now()}.pdf`;
  const filePath = path.join(outputDir, fileName);

  return new Promise((resolve, reject) => {
    const doc = new PDFDocument();
    const stream = fs.createWriteStream(filePath);
    doc.pipe(stream);

    // Header
    doc.fontSize(20).text('Booking Invoice', { align: 'center' });
    doc.moveDown();

    // Booking Info
    doc.fontSize(12).text(`Booking Number: ${invoiceData.booking_number || invoiceData.booking_id}`);
    doc.text(`Booking ID: ${invoiceData.booking_id}`);
    doc.text(`User: ${invoiceData.user_name || 'N/A'}`);
    doc.text(`Email: ${invoiceData.user_email || 'N/A'}`);
    doc.text(`Property: ${invoiceData.property_name || 'N/A'}`);
    doc.text(`Property Address: ${invoiceData.property_address || 'N/A'}`);
    doc.text(`Check-in: ${invoiceData.check_in || 'N/A'}`);
    doc.text(`Check-out: ${invoiceData.check_out || 'N/A'}`);
    doc.text(`No. of Guests: ${invoiceData.no_of_guests || 'N/A'}`);
    doc.text(`No. of Beds: ${invoiceData.no_of_beds || 'N/A'}`);
    doc.text(`Created At: ${invoiceData.created_at || 'N/A'}`);
    doc.text(`Updated At: ${invoiceData.updated_at || 'N/A'}`);
    doc.moveDown();

    // Pricing
    doc.fontSize(14).text('Pricing Details', { underline: true });
    doc.fontSize(12).text(`Base Price: ₹${invoiceData.price || 'N/A'}`);
    doc.text(`Tax: ₹${invoiceData.tax || 'N/A'} (${invoiceData.tax_percent || 'N/A'}%)`);
    doc.text(`Total Amount: ₹${invoiceData.amount || 'N/A'}`);
    doc.text(`Paid: ${invoiceData.is_paid ? 'Yes' : 'No'}`);
    doc.text(`Payment Mode: ${invoiceData.is_cod ? 'Cash on Delivery' : 'Online'}`);
    doc.moveDown();

    // Footer
    doc.text('Thank you for booking with Aajoo!', { align: 'center' });
    doc.end();

    stream.on('finish', () => resolve(filePath));
    stream.on('error', reject);
  });
}

module.exports = { generateInvoicePDF };