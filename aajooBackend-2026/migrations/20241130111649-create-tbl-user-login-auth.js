'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_user_login_auths', {
      la_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      la_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      la_token: {
        type: Sequelize.TEXT({ length: "long" }),
        allowNull: false
      },
      la_ip: {
        type: Sequelize.STRING(100)
      },
      la_addedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_user_login_auths');
  }
};