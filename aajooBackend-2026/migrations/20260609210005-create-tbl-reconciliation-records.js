'use strict';
/**
 * Migration: create tbl_reconciliation_records
 * Sprint: Full Delivery 2026-06-09..18 (A-02)
 * Authored by: Account A
 *
 * One row per booking after the nightly reconciliation job. Compares
 * what guest paid (book_total_amt) against gateway-captured amount
 * against host payout amount. Variance > 0 flags admin attention.
 */
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_reconciliation_records', {
      rr_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      rr_booking_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        comment: 'soft FK -> tbl_bookings.book_pri_id',
      },
      rr_payment_amount: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
        comment: 'amount captured by Razorpay',
      },
      rr_expected_amount: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
        comment: 'book_total_amt from tbl_bookings',
      },
      rr_payout_amount: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
        comment: 'amount paid to host',
      },
      rr_variance: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
        comment: 'expected - payment, or expected - (payout + commission + tax)',
      },
      rr_status: {
        type: Sequelize.ENUM('MATCHED', 'VARIANCE', 'PENDING', 'RESOLVED'),
        allowNull: false,
        defaultValue: 'PENDING',
      },
      rr_resolved_by: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        comment: 'soft FK -> tbl_admins.id',
      },
      rr_resolved_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      rr_action_taken: {
        type: Sequelize.ENUM('ADJUST', 'WRITE_OFF', 'REFUND'),
        allowNull: true,
      },
      rr_notes: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      rr_created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      rr_updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    await queryInterface.addIndex('tbl_reconciliation_records', ['rr_booking_id'], { name: 'idx_rr_booking_id' });
    await queryInterface.addIndex('tbl_reconciliation_records', ['rr_status'], { name: 'idx_rr_status' });
    await queryInterface.addIndex('tbl_reconciliation_records', ['rr_created_at'], { name: 'idx_rr_created_at' });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_reconciliation_records');
  },
};
