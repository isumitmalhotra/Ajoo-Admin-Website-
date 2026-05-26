'use strict';
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('tbl_user', 'user_last_intent', {
      type: Sequelize.STRING(100),
      allowNull: true,
      defaultValue: null
    });

    await queryInterface.addColumn('tbl_user', 'user_last_message', {
      type: Sequelize.TEXT,
      allowNull: true,
      defaultValue: null
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('tbl_user', 'user_last_intent');
    await queryInterface.removeColumn('tbl_user', 'user_last_message');
  }
};
