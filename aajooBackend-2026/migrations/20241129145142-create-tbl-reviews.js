'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_reviews', {
      br_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      br_book_id: {
        type: Sequelize.STRING(250),
        allowNull: false
      },
      br_propId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      br_hostId: {
        type: Sequelize.INTEGER(11),
        allowNull: true
      },
      br_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      br_rating: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false
      },
      br_title: {
        type: Sequelize.STRING(100),
      },
      br_desc: {
        type: Sequelize.TEXT()
      },
      br_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      br_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      br_addedAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      br_updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_reviews');
  }
};