'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_host_support_tickets', {
      hst_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false,
      },
      hst_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      hst_subject: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      hst_category: {
        type: Sequelize.STRING(100),
        allowNull: true,
      },
      hst_priority: {
        type: Sequelize.STRING(20),
        allowNull: true,
      },
      hst_status: {
        type: Sequelize.STRING(20),
        allowNull: false,
        defaultValue: 'open',
      },
      hst_description: {
        type: Sequelize.TEXT(),
        allowNull: false,
      },
      hst_resolution_note: {
        type: Sequelize.TEXT(),
        allowNull: true,
      },
      hst_is_active: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1,
      },
      hst_is_deleted: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_host_support_tickets');
  }
};
