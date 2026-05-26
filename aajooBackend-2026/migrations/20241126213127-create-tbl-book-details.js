'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_book_details', {
      bt_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      bt_book_pri_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      bt_book_id: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      bt_book_from: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      bt_book_to: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      bt_book_checkIn: {
        type: Sequelize.STRING(10),
        allowNull: false
      },
      bt_book_checkout: {
        type: Sequelize.STRING(10),
        allowNull: false
      },
      bt_book_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      bt_added_at: {
        allowNull: false,
        type: Sequelize.DATE
      },
      bt_update_at: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_book_details');
  }
};