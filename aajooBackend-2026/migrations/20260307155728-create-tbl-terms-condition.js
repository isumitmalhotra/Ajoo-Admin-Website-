'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_terms_Conditions', {
      tc_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      tc_title: {
        type: Sequelize.STRING,
        allowNull: false
      },
      tc_description: {
        type: Sequelize.TEXT,
        allowNull: false
      },
      tc_isActive: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 1
      },
      tc_type: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 1
      },
      tc_isdeleted: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 0
      },
      tc_created_at: {
        allowNull: false,
        type: Sequelize.DATE
      },
      tc_updated_at: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_terms_Conditions');
  }
};