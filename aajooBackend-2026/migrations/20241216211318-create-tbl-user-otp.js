'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_user_otps', {
      uo_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      uo_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      uo_otp: {
        type: Sequelize.STRING(20),
        allowNull: false
      },
      uo_createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_user_otps');
  }
};