'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_host_acc_details', {
      had_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        autoIncrement: true,
        primaryKey: true
      },
      had_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      had_acc_no: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      had_ifsc: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      had_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      had_isVerified: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
      },
      had_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
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
    await queryInterface.dropTable('tbl_host_acc_details');
  }
};