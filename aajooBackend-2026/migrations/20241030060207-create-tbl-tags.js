'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_tags', {
      tag_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      tag_name: {
        type: Sequelize.STRING(50),
        allowNull: false,
      },
      tag_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      tag_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_tags');
  }
};