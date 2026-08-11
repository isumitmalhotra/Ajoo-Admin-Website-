'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableName = 'tbl_property_details';
    const columnName = 'propDetail_no_of_guests';
    const table = await queryInterface.describeTable(tableName);

    if (!table[columnName]) {
      await queryInterface.addColumn(tableName, columnName, {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        defaultValue: null
      });
    }
  },

  async down(queryInterface, Sequelize) {
    const tableName = 'tbl_property_details';
    const columnName = 'propDetail_no_of_guests';
    const table = await queryInterface.describeTable(tableName);

    if (table[columnName]) {
      await queryInterface.removeColumn(tableName, columnName);
    }
  }
};
