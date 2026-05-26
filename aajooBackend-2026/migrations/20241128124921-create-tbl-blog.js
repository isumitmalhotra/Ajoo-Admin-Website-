'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_blogs', {
      blog_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      blog_title: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      blog_short_desc: {
        type: Sequelize.STRING(200),
        allowNull: false,
      },
      blog_long_desc: {
        type: Sequelize.TEXT()
      },
      blog_writerId: {
        type: Sequelize.TEXT(),
        defaultValue: 1
      },
      blog_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      blog_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      blog_addedAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      blog_updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_blogs');
  }
};