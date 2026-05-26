'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_amenities', {
      amn_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      amn_title: {
        type: Sequelize.STRING(20),
        allowNull: false
      },
      amn_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      amn_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_amenities');
  }
};