'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_blog_to_tags', {
      btt_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      btt_tag_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      btt_blog_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_blog_to_tags');
  }
};