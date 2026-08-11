'use strict';
/**
 * Migration: create tbl_support_tickets
 * Sprint: Full Delivery 2026-06-09..18 (A-07)
 */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.createTable('tbl_support_tickets', {
            st_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                primaryKey: true,
                autoIncrement: true,
            },
            st_host_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                comment: 'soft FK -> tbl_user.user_id (host)',
            },
            st_subject: {
                type: Sequelize.STRING(255),
                allowNull: false,
            },
            st_category: {
                type: Sequelize.ENUM('PAYOUT', 'BOOKING', 'PROFILE', 'GENERAL', 'OTHER'),
                allowNull: false,
                defaultValue: 'GENERAL',
            },
            st_status: {
                type: Sequelize.ENUM('OPEN', 'PENDING', 'RESOLVED', 'CLOSED'),
                allowNull: false,
                defaultValue: 'OPEN',
            },
            st_last_reply_at: {
                type: Sequelize.DATE,
                allowNull: true,
            },
            st_unread_count: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                defaultValue: 0,
            },
            st_created_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
            st_updated_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
        });

        await queryInterface.addIndex('tbl_support_tickets', ['st_host_id'], { name: 'idx_st_host_id' });
        await queryInterface.addIndex('tbl_support_tickets', ['st_status'], { name: 'idx_st_status' });
        await queryInterface.addIndex('tbl_support_tickets', ['st_category'], { name: 'idx_st_category' });
        await queryInterface.addIndex('tbl_support_tickets', ['st_created_at'], { name: 'idx_st_created_at' });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.dropTable('tbl_support_tickets');
    },
};
