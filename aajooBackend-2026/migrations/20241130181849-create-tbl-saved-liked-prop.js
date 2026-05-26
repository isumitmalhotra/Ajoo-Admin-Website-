'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_saved_liked_props', {
      slp_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      slp_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      slp_prop_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      slp_isSave: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      slp_isLike: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      slp_isDislike: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_saved_liked_props');
  }
};