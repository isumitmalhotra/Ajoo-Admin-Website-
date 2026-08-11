'use strict';
/**
 * Migration: create tbl_payouts
 * Sprint: Full Delivery 2026-06-09..18 (A-02)
 * Authored by: Account A
 *
 * New unified payout table. Coexists with `tbl_payout_req` (existing
 * host-side payout request flow) and `tbl_payout_history` (existing
 * payout history). New admin payout queue + execution log writes here.
 */
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_payouts', {
      po_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      po_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        comment: 'soft FK -> tbl_user.user_id (host)',
      },
      po_amount: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
      },
      po_status: {
        type: Sequelize.ENUM('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED'),
        allowNull: false,
        defaultValue: 'QUEUED',
      },
      po_payout_method: {
        type: Sequelize.ENUM('BANK_TRANSFER', 'UPI'),
        allowNull: false,
        defaultValue: 'BANK_TRANSFER',
      },
      po_reference_id: {
        type: Sequelize.STRING(255),
        allowNull: true,
        comment: 'Razorpay payout/transfer reference',
      },
      po_initiated_by: {
        type: Sequelize.ENUM('SYSTEM', 'ADMIN'),
        allowNull: false,
        defaultValue: 'SYSTEM',
      },
      po_initiated_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      po_completed_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      po_failure_reason: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      po_period_start: {
        type: Sequelize.DATEONLY,
        allowNull: true,
      },
      po_period_end: {
        type: Sequelize.DATEONLY,
        allowNull: true,
      },
      po_on_hold: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 0,
      },
      po_hold_reason: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      po_note: {
        type: Sequelize.TEXT,
        allowNull: true,
        comment: 'admin note when manually initiating',
      },
      po_created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      po_updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    await queryInterface.addIndex('tbl_payouts', ['po_host_id'], { name: 'idx_po_host_id' });
    await queryInterface.addIndex('tbl_payouts', ['po_status'], { name: 'idx_po_status' });
    await queryInterface.addIndex('tbl_payouts', ['po_initiated_at'], { name: 'idx_po_initiated_at' });
    await queryInterface.addIndex('tbl_payouts', ['po_created_at'], { name: 'idx_po_created_at' });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_payouts');
  },
};
