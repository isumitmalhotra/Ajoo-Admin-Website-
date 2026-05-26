'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_platform_reviews', {
      pr_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      pr_book_id: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      pr_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pr_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pr_rating: {
        type: Sequelize.TINYINT(1),
        allowNull: false
      },
      pr_title: {
        type: Sequelize.STRING(100),
        // allowNull: false
      },
      pr_description: {
        type: Sequelize.TEXT(),
        // allowNull: false
      },
      pr_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      pr_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_platform_reviews');
  }
};