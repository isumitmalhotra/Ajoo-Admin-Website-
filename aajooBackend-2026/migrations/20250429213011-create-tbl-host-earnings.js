'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_host_earnings', {
      he_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      he_booking_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      he_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      he_payment_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      he_amount: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false
      },
      he_invoice: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      he_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      he_isRecieved: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      he_isDeleted: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_host_earnings');
  }
};