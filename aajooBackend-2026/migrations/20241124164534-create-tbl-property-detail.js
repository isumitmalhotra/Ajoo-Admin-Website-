'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_property_details', {
      propDetail_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      propDetail_propId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      propDetail_isPetFriendly: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      propDetail_isSmoke: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
      },
      propDetail_inTime: {
        type: Sequelize.STRING(50),
        allowNull: true
      },
      propDetail_outTime: {
        type: Sequelize.STRING(50),
        allowNull: true
      },
      propDetail_no_of_beds: {
        type: Sequelize.STRING(250),
        allowNull: true
      },
      propDetail_weeklyMini_price: {
        type: Sequelize.DOUBLE(10, 2),
        defaultValue: 0.00
      },
      propDetail_weeklyMax_price: {
        type: Sequelize.DOUBLE(10, 2),
        defaultValue: 0.00
      },
      propDetail_monthly_security: {
        type: Sequelize.DOUBLE(10, 2),
        defaultValue: 0.00
      },
      propDetail_extra: {
        type: Sequelize.TEXT(),
        allowNull: true
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_property_details');
  }
};