'use strict';
/**
 * Migration: create tbl_invoices
 * Sprint: Full Delivery 2026-06-09..18 (A-02)
 * Authored by: Account A
 *
 * GST-compliant invoice store. Booking confirmation triggers a
 * BOOKING_RECEIPT row. Host commission and payout statement variants
 * follow the same shape via inv_invoice_type.
 */
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_invoices', {
      inv_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      inv_invoice_number: {
        type: Sequelize.STRING(50),
        allowNull: false,
        unique: true,
        comment: 'Format: AAJOO-INV-YYYYMM-XXXX',
      },
      inv_booking_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        comment: 'soft FK -> tbl_bookings.book_pri_id',
      },
      inv_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
      },
      inv_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
      },
      inv_invoice_type: {
        type: Sequelize.ENUM('BOOKING_RECEIPT', 'HOST_COMMISSION', 'PAYOUT_STATEMENT'),
        allowNull: false,
        defaultValue: 'BOOKING_RECEIPT',
      },
      inv_subtotal: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
      },
      inv_tax_amount: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
      },
      inv_tax_rate: {
        type: Sequelize.DECIMAL(5, 2),
        allowNull: false,
        defaultValue: 18.00,
        comment: 'GST percentage, e.g. 18.00',
      },
      inv_total: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
      },
      inv_hsn_sac_code: {
        type: Sequelize.STRING(32),
        allowNull: true,
        comment: 'GST classification code, e.g. 996311',
      },
      inv_gstin: {
        type: Sequelize.STRING(32),
        allowNull: true,
      },
      inv_pdf_url: {
        type: Sequelize.STRING(500),
        allowNull: true,
      },
      inv_line_items: {
        type: Sequelize.TEXT,
        allowNull: true,
        comment: 'JSON-stringified: [{description, quantity, rate, amount}]',
      },
      inv_status: {
        type: Sequelize.ENUM('GENERATED', 'SENT', 'VOID'),
        allowNull: false,
        defaultValue: 'GENERATED',
      },
      inv_void_reason: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      inv_created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      inv_updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    await queryInterface.addIndex('tbl_invoices', ['inv_booking_id'], { name: 'idx_inv_booking_id' });
    await queryInterface.addIndex('tbl_invoices', ['inv_host_id'], { name: 'idx_inv_host_id' });
    await queryInterface.addIndex('tbl_invoices', ['inv_user_id'], { name: 'idx_inv_user_id' });
    await queryInterface.addIndex('tbl_invoices', ['inv_invoice_type'], { name: 'idx_inv_invoice_type' });
    await queryInterface.addIndex('tbl_invoices', ['inv_status'], { name: 'idx_inv_status' });
    await queryInterface.addIndex('tbl_invoices', ['inv_created_at'], { name: 'idx_inv_created_at' });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_invoices');
  },
};
