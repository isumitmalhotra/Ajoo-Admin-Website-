'use strict';
module.exports = {
  async up(queryInterface, Sequelize) {
    const tableName = 'tbl_users';
    const table = await queryInterface.describeTable(tableName);

    if (!table.user_last_intent) {
      await queryInterface.addColumn(tableName, 'user_last_intent', {
        type: Sequelize.STRING(100),
        allowNull: true,
        defaultValue: null
      });
    }

    if (!table.user_last_message) {
      await queryInterface.addColumn(tableName, 'user_last_message', {
        type: Sequelize.TEXT,
        allowNull: true,
        defaultValue: null
      });
    }
  },

  async down(queryInterface, Sequelize) {
    const tableName = 'tbl_users';
    const table = await queryInterface.describeTable(tableName);

    if (table.user_last_intent) {
      await queryInterface.removeColumn(tableName, 'user_last_intent');
    }

    if (table.user_last_message) {
      await queryInterface.removeColumn(tableName, 'user_last_message');
    }
  }
};
