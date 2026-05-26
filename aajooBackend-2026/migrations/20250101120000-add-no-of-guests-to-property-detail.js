'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('tbl_property_details', 'propDetail_no_of_guests', {
      type: Sequelize.INTEGER(11),
      allowNull: true,
      defaultValue: null
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('tbl_property_details', 'propDetail_no_of_guests');
  }
};
