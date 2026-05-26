'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addIndex('tbl_properties', ['property_host_id']);
    await queryInterface.addIndex('tbl_properties', ['is_active']);
    await queryInterface.addIndex('tbl_properties', ['is_deleted']);
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeIndex('tbl_properties', ['property_host_id']);
    await queryInterface.removeIndex('tbl_properties', ['is_active']);
    await queryInterface.removeIndex('tbl_properties', ['is_deleted']);
  }
};
