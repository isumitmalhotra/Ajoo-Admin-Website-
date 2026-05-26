'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_payout_reqs', {
      pay_req_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      pay_req_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pay_req_amount: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false
      },
      pay_req_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pay_req_isActive: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1
      },
      pay_req_isDelete: {
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
    await queryInterface.dropTable('tbl_payout_reqs');
  }
};