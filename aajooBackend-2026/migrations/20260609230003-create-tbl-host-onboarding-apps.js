'use strict';
/**
 * Migration: create tbl_host_onboarding_apps
 * Sprint: Full Delivery 2026-06-09..18 (A-07)
 *
 * Captures "Become a Host" applications. Admin moderates these
 * before flipping the user's user_isHost flag.
 */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.createTable('tbl_host_onboarding_apps', {
            hoa_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                primaryKey: true,
                autoIncrement: true,
            },
            hoa_user_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                comment: 'soft FK -> tbl_user.user_id',
            },
            hoa_property_type: {
                type: Sequelize.STRING(100),
                allowNull: true,
            },
            hoa_city: {
                type: Sequelize.STRING(100),
                allowNull: true,
            },
            hoa_state: {
                type: Sequelize.STRING(100),
                allowNull: true,
            },
            hoa_country: {
                type: Sequelize.STRING(100),
                allowNull: true,
            },
            hoa_hosting_experience: {
                type: Sequelize.STRING(255),
                allowNull: true,
            },
            hoa_contact_name: {
                type: Sequelize.STRING(255),
                allowNull: true,
            },
            hoa_contact_phone: {
                type: Sequelize.STRING(32),
                allowNull: true,
            },
            hoa_message: {
                type: Sequelize.TEXT,
                allowNull: true,
            },
            hoa_status: {
                type: Sequelize.ENUM('RECEIVED', 'IN_REVIEW', 'APPROVED', 'REJECTED'),
                allowNull: false,
                defaultValue: 'RECEIVED',
            },
            hoa_admin_note: {
                type: Sequelize.TEXT,
                allowNull: true,
            },
            hoa_created_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
            hoa_updated_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
        });

        await queryInterface.addIndex('tbl_host_onboarding_apps', ['hoa_user_id'], { name: 'idx_hoa_user_id' });
        await queryInterface.addIndex('tbl_host_onboarding_apps', ['hoa_status'], { name: 'idx_hoa_status' });
        await queryInterface.addIndex('tbl_host_onboarding_apps', ['hoa_created_at'], { name: 'idx_hoa_created_at' });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.dropTable('tbl_host_onboarding_apps');
    },
};
