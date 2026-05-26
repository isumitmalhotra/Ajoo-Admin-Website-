'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_bookings', {
      book_pri_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true
      },
      book_id: {
        type: Sequelize.STRING(100),
        allowNull: false,
      },
      book_invoice: {
        type: Sequelize.STRING(100)
      },
      book_prop_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      book_prop_type: {
        type: Sequelize.INTEGER(),
      },
      book_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      book_host_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      book_price: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false,
      },
      book_tax: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false,
      },
      book_tax_percentagenatage: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false,
      },
      book_total_amt: {
        type: Sequelize.DOUBLE(10, 2),
        allowNull: false,
      },
      book_is_paid: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 0
      },
      book_is_cod: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 0
      },
      book_status: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },

      book_no_of_guests: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      book_no_of_beds: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      book_is_delete: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 0
      },
      book_added_at: {
        allowNull: false,
        type: Sequelize.DATE
      },
      book_updated_at: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_bookings');
  }
};