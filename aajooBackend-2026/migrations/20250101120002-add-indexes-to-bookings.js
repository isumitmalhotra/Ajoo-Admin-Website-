'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableName = 'tbl_bookings';
    const existingIndexes = await queryInterface.showIndex(tableName);
    const existingIndexNames = new Set(existingIndexes.map(index => index.name));

    if (!existingIndexNames.has('tbl_bookings_book_prop_id')) {
      await queryInterface.addIndex(tableName, ['book_prop_id']);
    }

    if (!existingIndexNames.has('tbl_bookings_book_user_id')) {
      await queryInterface.addIndex(tableName, ['book_user_id']);
    }

    if (!existingIndexNames.has('tbl_bookings_book_host_id')) {
      await queryInterface.addIndex(tableName, ['book_host_id']);
    }
  },

  async down(queryInterface, Sequelize) {
    const tableName = 'tbl_bookings';
    const existingIndexes = await queryInterface.showIndex(tableName);
    const existingIndexNames = new Set(existingIndexes.map(index => index.name));

    if (existingIndexNames.has('tbl_bookings_book_prop_id')) {
      await queryInterface.removeIndex(tableName, ['book_prop_id']);
    }

    if (existingIndexNames.has('tbl_bookings_book_user_id')) {
      await queryInterface.removeIndex(tableName, ['book_user_id']);
    }

    if (existingIndexNames.has('tbl_bookings_book_host_id')) {
      await queryInterface.removeIndex(tableName, ['book_host_id']);
    }
  }
};
