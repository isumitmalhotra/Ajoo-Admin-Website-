'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_admins', {
      admin_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      admin_name: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      admin_username: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      admin_email: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      admin_password: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      admin_last_login: {
        type: Sequelize.DATE
      },
      admin_isAdmin: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      admin_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      created_at: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updated_at: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_admins');
  }
};