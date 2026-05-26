'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_book_statuses', {
      bs_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      bs_title: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      bs_code: {
        type:Sequelize.STRING(50)
      },
      bs_isDelete: {
        type:Sequelize.TINYINT(1),
        defaultValue:0
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_book_statuses');
  }
};