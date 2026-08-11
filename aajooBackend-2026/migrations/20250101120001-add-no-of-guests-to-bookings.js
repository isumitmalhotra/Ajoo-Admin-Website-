'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableName = 'tbl_bookings';
    const table = await queryInterface.describeTable(tableName);

    if (!table.book_no_of_guests) {
      await queryInterface.addColumn(tableName, 'book_no_of_guests', {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        defaultValue: null
      });
    }

    if (!table.book_no_of_beds) {
      await queryInterface.addColumn(tableName, 'book_no_of_beds', {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        defaultValue: null
      });
    }
  },

  async down(queryInterface, Sequelize) {
    const tableName = 'tbl_bookings';
    const table = await queryInterface.describeTable(tableName);

    if (table.book_no_of_guests) {
      await queryInterface.removeColumn(tableName, 'book_no_of_guests');
    }

    if (table.book_no_of_beds) {
      await queryInterface.removeColumn(tableName, 'book_no_of_beds');
    }
  }
};
