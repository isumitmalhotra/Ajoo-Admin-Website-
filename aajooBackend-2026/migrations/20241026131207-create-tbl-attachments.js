'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_attachments', {
      afile_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      afile_type: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      afile_record_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      afile_path: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      afile_cldId: {
        type: Sequelize.TEXT(),
        allowNull: false
      },
      afile_name: {
        type: Sequelize.STRING(255),
        allowNull: true
      },
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_attachments');
  }
};