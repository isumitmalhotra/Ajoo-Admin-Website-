'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_user_creds', {
      cred_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      cred_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      cred_username: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      cred_user_email: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      cred_user_password: {
        type: Sequelize.STRING(200),
        allowNull: false
      },
      // cred_user_doc_type: {
      //   type: Sequelize.INTEGER(11),
      //   allowNull: false
      // },
      // cred_user_doc_number: {
      //   type: Sequelize.STRING(50),
      //   allowNull: false
      // },
      cred_user_refrel: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
        comment: "0 is default"
      },
      cred_user_isHost: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
        comment: "0 is default"
      },
      cred_user_isUser: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
        comment: "0 is default"
      },
      cred_user_isDelete: {
        type: Sequelize.TINYINT(1),
        defaultValue: 0,
        comment: "0 is default"
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_user_creds');
  }
};