'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableName = 'tbl_properties';
    const existingIndexes = await queryInterface.showIndex(tableName);
    const existingIndexNames = new Set(existingIndexes.map(index => index.name));

    if (!existingIndexNames.has('tbl_properties_property_host_id')) {
      await queryInterface.addIndex(tableName, ['property_host_id']);
    }

    if (!existingIndexNames.has('tbl_properties_is_active')) {
      await queryInterface.addIndex(tableName, ['is_active']);
    }

    if (!existingIndexNames.has('tbl_properties_is_deleted')) {
      await queryInterface.addIndex(tableName, ['is_deleted']);
    }
  },

  async down(queryInterface, Sequelize) {
    const tableName = 'tbl_properties';
    const existingIndexes = await queryInterface.showIndex(tableName);
    const existingIndexNames = new Set(existingIndexes.map(index => index.name));

    if (existingIndexNames.has('tbl_properties_property_host_id')) {
      await queryInterface.removeIndex(tableName, ['property_host_id']);
    }

    if (existingIndexNames.has('tbl_properties_is_active')) {
      await queryInterface.removeIndex(tableName, ['is_active']);
    }

    if (existingIndexNames.has('tbl_properties_is_deleted')) {
      await queryInterface.removeIndex(tableName, ['is_deleted']);
    }
  }
};
