'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_host_review_for_users', {
      hru_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
      },
      hru_hostId: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      hru_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      hru_bookingPriId: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      hru_propId: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      hru_bookingId: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      hru_title: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      hru_description: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      hru_rating: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false,
      },
      hru_isActive: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 1,
      },
      hru_isDelete: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 0,
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
    await queryInterface.dropTable('tbl_host_review_for_users');
  }
};