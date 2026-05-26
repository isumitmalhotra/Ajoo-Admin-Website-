'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_categories', {
      cat_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        autoIncrement: true,
        primaryKey: true
      },
      cat_title: {
        type: Sequelize.STRING(200),
        allowNull: false,
      },
      cat_slug: {
        type: Sequelize.STRING(255)
      },
      cat_isActive: {
        type: Sequelize.STRING(200),
        defaultValue: 1
      },
      cat_isDelete: {
        type: Sequelize.STRING(200),
        defaultValue: 10
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
    await queryInterface.dropTable('tbl_categories');
  }
};