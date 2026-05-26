'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_user_notifications', {
      un_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      un_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      un_propId: {
        type: Sequelize.INTEGER(11),
      },
      un_bookingId: {
        type: Sequelize.STRING(255),
      },
      un_pri_bookingId: {
        type: Sequelize.INTEGER(11)
      },
      un_title: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      un_message: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      un_is_read: {
        type: Sequelize.TINYINT(1),
        allowNull: false
      },
      un_payload: {
        type: Sequelize.JSON(500),
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
    await queryInterface.dropTable('tbl_user_notifications');
  }
};