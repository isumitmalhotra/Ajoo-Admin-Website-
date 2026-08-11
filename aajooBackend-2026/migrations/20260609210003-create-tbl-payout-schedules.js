'use strict';
/**
 * Migration: create tbl_payout_schedules
 * Sprint: Full Delivery 2026-06-09..18 (A-02)
 * Authored by: Account A
 *
 * One row per host defining auto-payout cadence. The scheduler job
 * (FMS_PLAN.md § 7.1 payoutSchedulerJob) reads this nightly.
 */
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_payout_schedules', {
      ps_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      ps_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        unique: true,
        comment: 'soft FK -> tbl_user.user_id (host); one schedule per host',
      },
      ps_frequency: {
        type: Sequelize.ENUM('DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY'),
        allowNull: false,
        defaultValue: 'WEEKLY',
      },
      ps_next_payout_date: {
        type: Sequelize.DATEONLY,
        allowNull: true,
      },
      ps_last_payout_date: {
        type: Sequelize.DATEONLY,
        allowNull: true,
      },
      ps_min_payout_amount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
        defaultValue: 100.00,
      },
      ps_is_active: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 1,
      },
      ps_payout_method: {
        type: Sequelize.ENUM('BANK_TRANSFER', 'UPI'),
        allowNull: false,
        defaultValue: 'BANK_TRANSFER',
      },
      ps_account_details: {
        type: Sequelize.TEXT,
        allowNull: true,
        comment: 'JSON-stringified, masked: {accountNumber: "XXXX1234", ifsc, upiId}',
      },
      ps_created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      ps_updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    await queryInterface.addIndex('tbl_payout_schedules', ['ps_next_payout_date'], { name: 'idx_ps_next_payout_date' });
    await queryInterface.addIndex('tbl_payout_schedules', ['ps_is_active'], { name: 'idx_ps_is_active' });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_payout_schedules');
  },
};
