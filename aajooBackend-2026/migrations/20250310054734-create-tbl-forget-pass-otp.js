'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_forget_pass_otps', {
      fpo_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      fpo_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      fpo_otp: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      fpo_email: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      fpo_type: {
        type: Sequelize.TINYINT(1),
        allowNull: false
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
    await queryInterface.dropTable('tbl_forget_pass_otps');
  }
};