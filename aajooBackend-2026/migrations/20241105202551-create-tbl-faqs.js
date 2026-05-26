'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_faqs', {
      faq_id: {
        type: Sequelize.INTEGER(11),
        primaryKey: true,
        allowNull: false,
        autoIncrement: true,
      },

      faq_question: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },

      faq_answer: {
        type: Sequelize.TEXT,
        allowNull: false,
      },

      faq_category: {
        type: Sequelize.STRING(100),
        allowNull: true,
      },

      faq_display_order: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        defaultValue: 0,
      },

      faq_is_active: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 1, // 1 = active, 0 = inactive
      },

      faq_is_delete: {
        type: Sequelize.TINYINT(1),
        allowNull: false,
        defaultValue: 0, // 0 = not deleted, 1 = deleted
      },

      faq_created_by: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
      },

      faq_updated_by: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
      },
      faq_created_at: {
        allowNull: false,
        type: Sequelize.DATE
      },
      faq_updated_at: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('tbl_faqs');
  }
};