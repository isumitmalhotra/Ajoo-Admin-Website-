'use strict';
/**
 * Migration: add guest KYC columns to tbl_bookings
 * Sprint: Full Delivery 2026-06-09..18 (A-11)
 * Uses information_schema existence checks (Clever Cloud describeTable quirk). Idempotent.
 */
module.exports = {
    async up(queryInterface, Sequelize) {
        const columnExists = async (table, column) => {
            const [rows] = await queryInterface.sequelize.query(
                "SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = :t AND column_name = :c",
                { replacements: { t: table, c: column } }
            );
            return rows.length > 0;
        };
        const indexExists = async (table, indexName) => {
            const [rows] = await queryInterface.sequelize.query(
                "SELECT INDEX_NAME FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = :t AND index_name = :i",
                { replacements: { t: table, i: indexName } }
            );
            return rows.length > 0;
        };

        if (!(await columnExists('tbl_bookings', 'guest_verification_status'))) {
            await queryInterface.addColumn('tbl_bookings', 'guest_verification_status', {
                type: Sequelize.ENUM('unverified', 'pending', 'verified', 'declined', 'in_review'),
                allowNull: false, defaultValue: 'unverified',
            });
        }
        if (!(await columnExists('tbl_bookings', 'guest_didit_session_id'))) {
            await queryInterface.addColumn('tbl_bookings', 'guest_didit_session_id', {
                type: Sequelize.STRING(64), allowNull: true,
            });
        }
        if (!(await indexExists('tbl_bookings', 'idx_booking_guest_session_id'))) {
            await queryInterface.addIndex('tbl_bookings', ['guest_didit_session_id'], { name: 'idx_booking_guest_session_id' });
        }
    },

    async down(queryInterface, Sequelize) {
        try { await queryInterface.removeIndex('tbl_bookings', 'idx_booking_guest_session_id'); } catch (e) { /* noop */ }
        try { await queryInterface.removeColumn('tbl_bookings', 'guest_verification_status'); } catch (e) { /* noop */ }
        try { await queryInterface.removeColumn('tbl_bookings', 'guest_didit_session_id'); } catch (e) { /* noop */ }
    },
};
