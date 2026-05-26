'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_blog_tags', {
      bt_id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      bt_title: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      bt_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      bt_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_blog_tags');
  }
};