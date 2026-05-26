'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_payout_histories', {
      poh_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false,
      },
      poh_pay_req_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      poh_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      poh_amount: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false,
      },
      poh_invoice: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      poh_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
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
    await queryInterface.dropTable('tbl_payout_histories');
  }
};