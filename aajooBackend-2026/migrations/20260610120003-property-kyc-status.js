'use strict';
/**
 * Migration: add property_kyc_status to tbl_properties
 * Sprint: Full Delivery 2026-06-09..18 (A-11)
 *
 * New nullable KYC-gate column (NULL = legacy/ungated). Avoids ALTERing the
 * existing properties_status_flags enum. Uses information_schema checks
 * (Clever Cloud describeTable quirk). Idempotent.
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

        if (!(await columnExists('tbl_properties', 'property_kyc_status'))) {
            await queryInterface.addColumn('tbl_properties', 'property_kyc_status', {
                type: Sequelize.ENUM('active', 'pending_verification'),
                allowNull: true, defaultValue: null,
            });
        }
        if (!(await indexExists('tbl_properties', 'idx_property_kyc_status'))) {
            await queryInterface.addIndex('tbl_properties', ['property_kyc_status'], { name: 'idx_property_kyc_status' });
        }
    },

    async down(queryInterface, Sequelize) {
        try { await queryInterface.removeIndex('tbl_properties', 'idx_property_kyc_status'); } catch (e) { /* noop */ }
        try { await queryInterface.removeColumn('tbl_properties', 'property_kyc_status'); } catch (e) { /* noop */ }
    },
};
