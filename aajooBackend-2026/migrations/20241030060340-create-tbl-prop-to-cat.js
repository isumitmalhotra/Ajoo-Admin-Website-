'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_prop_to_cats', {
      pt_cat_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        autoIncrement: true,
        primaryKey: true
      },
      pt_cat_cat_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pt_cat_prop_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_prop_to_cats');
  }
};