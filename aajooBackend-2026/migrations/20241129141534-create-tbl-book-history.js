'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_book_histories', {
      bh_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      bh_book_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      bh_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      bh_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      bh_prop_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      bh_pay_id: {
        type: Sequelize.INTEGER(11)
      },
      bh_pay_id: {
        type: Sequelize.INTEGER(11)
      },
      bh_price: {
        type: Sequelize.DOUBLE(10, 2)
      },
      bh_status_id: {
        type: Sequelize.INTEGER(11)
      },
      bh_title: {
        type: Sequelize.STRING(100)
      },
      bh_description: {
        type: Sequelize.STRING(255),
      },
      bh_addedAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      bh_updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_book_histories');
  }
};