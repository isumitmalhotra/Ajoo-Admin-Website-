'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_histories', {
      his_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      his_bookId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      his_propId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      his_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      his_hostId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      his_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      his_title: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      his_desc: {
        type: Sequelize.TEXT(),
      },
      his_addedAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      his_updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_histories');
  }
};