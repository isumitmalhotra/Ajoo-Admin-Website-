'use strict';
/**
 * Migration: create tbl_financial_ledger
 * Sprint: Full Delivery 2026-06-09..18 (A-02)
 * Authored by: Account A
 *
 * Unified ledger for every financial movement on the platform.
 * Coexists with existing `tbl_host_earnings`, `tbl_payout_history`,
 * `tbl_payout_req`. Future writes (post Day-2 cutover) populate THIS
 * table; old tables remain for historical compatibility. No data
 * migration in sprint scope.
 *
 * Apply with: `npx sequelize-cli db:migrate`
 * Rollback:   `npx sequelize-cli db:migrate:undo`
 */
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_financial_ledger', {
      fl_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      fl_booking_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        comment: 'soft FK -> tbl_bookings.book_pri_id',
      },
      fl_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        comment: 'soft FK -> tbl_user.user_id (host)',
      },
      fl_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        comment: 'soft FK -> tbl_user.user_id (guest)',
      },
      fl_transaction_type: {
        type: Sequelize.ENUM(
          'GUEST_PAYMENT',
          'HOST_EARNING',
          'PLATFORM_COMMISSION',
          'TAX_COLLECTED',
          'REFUND',
          'PAYOUT',
          'ADJUSTMENT'
        ),
        allowNull: false,
      },
      fl_entry_type: {
        type: Sequelize.ENUM('CREDIT', 'DEBIT'),
        allowNull: false,
      },
      fl_amount: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: false,
        defaultValue: 0.00,
      },
      fl_balance_after: {
        type: Sequelize.DECIMAL(12, 2),
        allowNull: true,
      },
      fl_reference_id: {
        type: Sequelize.STRING(255),
        allowNull: true,
        comment: 'Razorpay payment_id / payout_id / refund_id',
      },
      fl_description: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      fl_status: {
        type: Sequelize.ENUM('COMPLETED', 'PENDING', 'FAILED', 'REVERSED'),
        allowNull: false,
        defaultValue: 'COMPLETED',
      },
      fl_created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      fl_updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    await queryInterface.addIndex('tbl_financial_ledger', ['fl_booking_id'], { name: 'idx_fl_booking_id' });
    await queryInterface.addIndex('tbl_financial_ledger', ['fl_host_id'], { name: 'idx_fl_host_id' });
    await queryInterface.addIndex('tbl_financial_ledger', ['fl_user_id'], { name: 'idx_fl_user_id' });
    await queryInterface.addIndex('tbl_financial_ledger', ['fl_transaction_type'], { name: 'idx_fl_transaction_type' });
    await queryInterface.addIndex('tbl_financial_ledger', ['fl_status'], { name: 'idx_fl_status' });
    await queryInterface.addIndex('tbl_financial_ledger', ['fl_created_at'], { name: 'idx_fl_created_at' });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_financial_ledger');
  },
};
