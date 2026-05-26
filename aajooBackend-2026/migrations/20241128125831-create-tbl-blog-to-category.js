'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_blog_to_categories', {
      btc_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      btc_cat_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      btc_blog_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_blog_to_categories');
  }
};