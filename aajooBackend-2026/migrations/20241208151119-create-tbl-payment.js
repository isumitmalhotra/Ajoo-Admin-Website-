'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_payments', {
      pay_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      pay_raz_id: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      pay_order_id: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      pay_receipt_id: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      pay_bookId: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      pay_book_pri_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pay_userId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pay_hostId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pay_propId: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pay_invoice: {
        type: Sequelize.STRING(50),
        allowNull: false
      },
      pay_amount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false
      },
      pay_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      pay_status_text: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      pay_addedAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      pay_updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_payments');
  }
};