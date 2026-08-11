'use strict';
/**
 * Migration: add Didit KYC columns to tbl_users
 * Sprint: Full Delivery 2026-06-09..18 (A-11)
 *
 * NOTE: the live table is `tbl_users` (Sequelize pluralizes the `tbl_user`
 * model name). Uses information_schema existence checks (Clever Cloud MySQL
 * chokes on describeTable). Fully idempotent.
 */
const USER_TABLE = 'tbl_users';

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

        if (!(await columnExists(USER_TABLE, 'didit_session_id'))) {
            await queryInterface.addColumn(USER_TABLE, 'didit_session_id', {
                type: Sequelize.STRING(64), allowNull: true,
            });
        }
        if (!(await columnExists(USER_TABLE, 'verification_status'))) {
            await queryInterface.addColumn(USER_TABLE, 'verification_status', {
                type: Sequelize.ENUM('unverified', 'pending', 'verified', 'declined', 'in_review'),
                allowNull: false, defaultValue: 'unverified',
            });
        }
        if (!(await columnExists(USER_TABLE, 'verified_at'))) {
            await queryInterface.addColumn(USER_TABLE, 'verified_at', {
                type: Sequelize.DATE, allowNull: true,
            });
        }
        if (!(await columnExists(USER_TABLE, 'verification_expires_at'))) {
            await queryInterface.addColumn(USER_TABLE, 'verification_expires_at', {
                type: Sequelize.DATE, allowNull: true,
            });
        }

        if (!(await indexExists(USER_TABLE, 'idx_user_didit_session_id'))) {
            await queryInterface.addIndex(USER_TABLE, ['didit_session_id'], { name: 'idx_user_didit_session_id' });
        }
        if (!(await indexExists(USER_TABLE, 'idx_user_verification_status'))) {
            await queryInterface.addIndex(USER_TABLE, ['verification_status'], { name: 'idx_user_verification_status' });
        }
    },

    async down(queryInterface, Sequelize) {
        try { await queryInterface.removeIndex(USER_TABLE, 'idx_user_didit_session_id'); } catch (e) { /* noop */ }
        try { await queryInterface.removeIndex(USER_TABLE, 'idx_user_verification_status'); } catch (e) { /* noop */ }
        try { await queryInterface.removeColumn(USER_TABLE, 'didit_session_id'); } catch (e) { /* noop */ }
        try { await queryInterface.removeColumn(USER_TABLE, 'verification_status'); } catch (e) { /* noop */ }
        try { await queryInterface.removeColumn(USER_TABLE, 'verified_at'); } catch (e) { /* noop */ }
        try { await queryInterface.removeColumn(USER_TABLE, 'verification_expires_at'); } catch (e) { /* noop */ }
    },
};
