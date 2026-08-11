'use strict';
/**
 * Migration: create tbl_admin_flags
 * Sprint: Full Delivery 2026-06-09..18 (A-11)
 *
 * In-review queue for admin attention. KYC `in_review` webhook outcomes create
 * a flag row that surfaces in the admin Verification Queue (KYC-ADM-01).
 */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.createTable('tbl_admin_flags', {
            af_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                primaryKey: true,
                autoIncrement: true,
            },
            af_user_id: {
                type: Sequelize.INTEGER(11),
                allowNull: true,
                comment: 'soft FK -> tbl_user.user_id',
            },
            af_session_id: {
                type: Sequelize.STRING(64),
                allowNull: true,
                comment: 'Didit session id',
            },
            af_flag_type: {
                type: Sequelize.ENUM('KYC_IN_REVIEW', 'KYC_DECLINED', 'PAYOUT_VARIANCE', 'OTHER'),
                allowNull: false,
                defaultValue: 'KYC_IN_REVIEW',
            },
            af_subject_role: {
                type: Sequelize.ENUM('HOST', 'GUEST'),
                allowNull: true,
            },
            af_resolved: {
                type: Sequelize.TINYINT(1),
                allowNull: false,
                defaultValue: 0,
            },
            af_resolved_by: {
                type: Sequelize.INTEGER(11),
                allowNull: true,
            },
            af_notes: {
                type: Sequelize.TEXT,
                allowNull: true,
            },
            af_created_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
            af_updated_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
        });

        await queryInterface.addIndex('tbl_admin_flags', ['af_user_id'], { name: 'idx_af_user_id' });
        await queryInterface.addIndex('tbl_admin_flags', ['af_resolved'], { name: 'idx_af_resolved' });
        await queryInterface.addIndex('tbl_admin_flags', ['af_flag_type'], { name: 'idx_af_flag_type' });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.dropTable('tbl_admin_flags');
    },
};
