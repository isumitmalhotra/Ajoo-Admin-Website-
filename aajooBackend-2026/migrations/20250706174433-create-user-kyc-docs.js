'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('user_kyc_docs', {
      ud_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
        primaryKey: true,
        autoIncrement: true,
      },
      ud_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      ud_acc_doc_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      ud_number: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      ud_afile_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false,
      },
      ud_isVerified: {
        type: Sequelize.TINYINT(1),
        defaultValue: 1,
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('user_kyc_docs');
  }
};