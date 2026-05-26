'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_user_pass_auths', {
      upa_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      upa_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      upa_token: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      // upa_otp: {
      //   type: Sequelize.TEXT(),
      //   // allowNull: false
      // },
      upa_addedAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      upa_updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_user_pass_auths');
  }
};