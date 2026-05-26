'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addIndex('tbl_bookings', ['book_prop_id']);
    await queryInterface.addIndex('tbl_bookings', ['book_user_id']);
    await queryInterface.addIndex('tbl_bookings', ['book_host_id']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeIndex('tbl_bookings', ['book_prop_id']);
    await queryInterface.removeIndex('tbl_bookings', ['book_user_id']);
    await queryInterface.removeIndex('tbl_bookings', ['book_host_id']);
  }
};
