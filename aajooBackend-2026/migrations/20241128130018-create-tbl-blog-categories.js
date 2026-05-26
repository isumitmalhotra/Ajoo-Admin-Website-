'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_blog_categories', {
      bc_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      bc_title: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      bc_description: {
        type: Sequelize.STRING(200)
      },
      bc_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      bc_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_blog_categories');
  }
};