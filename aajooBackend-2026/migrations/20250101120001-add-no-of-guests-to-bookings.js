'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('tbl_bookings', 'book_no_of_guests', {
      type: Sequelize.INTEGER(11),
      allowNull: true,
      defaultValue: null
    });
    await queryInterface.addColumn('tbl_bookings', 'book_no_of_beds', {
      type: Sequelize.INTEGER(11),
      allowNull: true,
      defaultValue: null
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('tbl_bookings', 'book_no_of_guests');
    await queryInterface.removeColumn('tbl_bookings', 'book_no_of_beds');
  }
};
