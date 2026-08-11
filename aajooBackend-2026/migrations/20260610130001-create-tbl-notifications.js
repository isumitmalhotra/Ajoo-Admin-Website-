'use strict';
/**
 * Migration: create tbl_notifications
 * Sprint: Full Delivery 2026-06-09..18 (A-14)
 *
 * One table for admin + host (+ guest) notifications, partitioned by
 * ntf_recipient_role. Polling endpoints filter by role + recipient id.
 * (WebSocket push is a post-sprint upgrade; socket.io infra already present.)
 */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.createTable('tbl_notifications', {
            ntf_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                primaryKey: true,
                autoIncrement: true,
            },
            ntf_recipient_role: {
                type: Sequelize.ENUM('ADMIN', 'HOST', 'GUEST'),
                allowNull: false,
            },
            ntf_recipient_id: {
                type: Sequelize.INTEGER(11),
                allowNull: true,
                comment: 'user/admin id; NULL = broadcast to all of that role',
            },
            ntf_category: {
                type: Sequelize.ENUM('BOOKING', 'USER', 'HOST', 'PAYOUT', 'KYC', 'SYSTEM'),
                allowNull: false,
                defaultValue: 'SYSTEM',
            },
            ntf_title: {
                type: Sequelize.STRING(255),
                allowNull: false,
            },
            ntf_body: {
                type: Sequelize.TEXT,
                allowNull: true,
            },
            ntf_link_path: {
                type: Sequelize.STRING(255),
                allowNull: true,
                comment: 'FE route to deep-link, e.g. /admin/host',
            },
            ntf_is_read: {
                type: Sequelize.TINYINT(1),
                allowNull: false,
                defaultValue: 0,
            },
            ntf_created_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
            ntf_updated_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
        });

        await queryInterface.addIndex('tbl_notifications', ['ntf_recipient_role', 'ntf_recipient_id'], { name: 'idx_ntf_recipient' });
        await queryInterface.addIndex('tbl_notifications', ['ntf_is_read'], { name: 'idx_ntf_is_read' });
        await queryInterface.addIndex('tbl_notifications', ['ntf_created_at'], { name: 'idx_ntf_created_at' });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.dropTable('tbl_notifications');
    },
};
