'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_send_emails', {
      se_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      se_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: false
      },
      se_recipient_email: {
        type: Sequelize.STRING(255),
        allowNull: false
      },
      se_subject: {
        type: Sequelize.TEXT()
      },
      se_body: {
        type: Sequelize.TEXT()
      },
      se_status: {
        type: Sequelize.STRING(100),
        allowNull: false
      },
      se_cc: {
        type: Sequelize.STRING(255),
      },
      se_bcc: {
        type: Sequelize.STRING(255),
      },
      se_attachment: {
        type: Sequelize.TEXT()
      },
      se_template_id: {
        type: Sequelize.INTEGER(11)
      },
      se_mail_type: {
        type: Sequelize.TEXT(),
        allowNull: false
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
    await queryInterface.dropTable('tbl_send_emails');
  }
};