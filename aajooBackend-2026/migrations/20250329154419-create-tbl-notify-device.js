'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_notify_devices', {
      nd_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      nd_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      nd_user_email: {
        type: Sequelize.STRING(100)
      },
      nd_device_type: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1,
      },
      nd_device_token: {
        type: Sequelize.TEXT(),
        allowNull: false,
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
    await queryInterface.dropTable('tbl_notify_devices');
  }
};