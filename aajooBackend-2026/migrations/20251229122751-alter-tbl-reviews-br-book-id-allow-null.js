'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.changeColumn('tbl_reviews', 'br_book_id', {
      type: Sequelize.STRING(250),
      allowNull: true
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.changeColumn('tbl_reviews', 'br_book_id', {
      type: Sequelize.STRING(250),
      allowNull: false
    });
  }
};