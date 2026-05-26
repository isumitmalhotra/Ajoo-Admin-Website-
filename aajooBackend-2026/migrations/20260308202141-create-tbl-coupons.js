'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_coupons', {
      cpn_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      cpn_title: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      cpn_code: {
        type: Sequelize.STRING(100),
        allowNull: false,
        unique: true
      },
      cpn_type: {
        type: Sequelize.TINYINT(1),
        allowNull: false
      },
      cpn_dsctn_type: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      cpn_dsctn_percnt: {

        type: Sequelize.INTEGER(11),
        allowNull: true

      },
      cpn_dsctn_amt: {
        type: Sequelize.DOUBLE(10, 2),
        // allowNull: true
      },
      cpn_min_amt: {
        type: Sequelize.DOUBLE(10, 2),
        // allowNull: true
      },
      cpn_max_amt: {
        type: Sequelize.DOUBLE(10, 2),
        // allowNull: true
      },
      cpn_valid_from: {
        type: Sequelize.DATE,
      },
      cpn_valid_to: {
        type: Sequelize.DATE,
      },
      cpn_usage_limit: {
        type: Sequelize.INTEGER(11),
      },
      cpn_used_count: {
        type: Sequelize.INTEGER(11),
      },
      cpn_status: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      cpn_isDeleted: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0
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
    await queryInterface.dropTable('tbl_coupons');
  }
};