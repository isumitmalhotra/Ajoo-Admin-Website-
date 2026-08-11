'use strict';
/**
 * Migration: create tbl_support_ticket_messages
 * Sprint: Full Delivery 2026-06-09..18 (A-07)
 */
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.createTable('tbl_support_ticket_messages', {
            stm_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                primaryKey: true,
                autoIncrement: true,
            },
            stm_ticket_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
                comment: 'FK -> tbl_support_tickets.st_id',
            },
            stm_sender_role: {
                type: Sequelize.ENUM('HOST', 'SUPPORT', 'ADMIN'),
                allowNull: false,
            },
            stm_sender_id: {
                type: Sequelize.INTEGER(11),
                allowNull: false,
            },
            stm_message: {
                type: Sequelize.TEXT,
                allowNull: false,
            },
            stm_is_read: {
                type: Sequelize.TINYINT(1),
                allowNull: false,
                defaultValue: 0,
            },
            stm_created_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
            stm_updated_at: {
                type: Sequelize.DATE,
                allowNull: false,
            },
        });

        await queryInterface.addIndex('tbl_support_ticket_messages', ['stm_ticket_id'], { name: 'idx_stm_ticket_id' });
        await queryInterface.addIndex('tbl_support_ticket_messages', ['stm_created_at'], { name: 'idx_stm_created_at' });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.dropTable('tbl_support_ticket_messages');
    },
};
