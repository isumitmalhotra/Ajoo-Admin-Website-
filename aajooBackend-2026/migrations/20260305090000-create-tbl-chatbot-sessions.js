'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('tbl_chatbot_sessions', {
      cs_id: {
        type: Sequelize.INTEGER(11),
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
      cs_session_id: {
        type: Sequelize.STRING(80),
        allowNull: false,
        unique: true,
      },
      cs_channel_type: {
        type: Sequelize.ENUM('app', 'web', 'whatsapp'),
        allowNull: false,
        defaultValue: 'web',
      },
      cs_user_id: {
        type: Sequelize.INTEGER(11),
        allowNull: true,
        references: {
          model: 'tbl_users',
          key: 'user_id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      cs_user_name: {
        type: Sequelize.STRING(100),
        allowNull: true,
        defaultValue: 'Guest',
      },
      cs_user_role: {
        type: Sequelize.ENUM('guest', 'host'),
        allowNull: true,
      },
      cs_phone: {
        type: Sequelize.STRING(20),
        allowNull: true,
      },
      cs_language_pref: {
        type: Sequelize.ENUM('en', 'hi'),
        allowNull: false,
        defaultValue: 'en',
      },
      cs_stage: {
        type: Sequelize.STRING(50),
        allowNull: false,
        defaultValue: 'language_selection',
      },
      cs_context: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      cs_last_intent: {
        type: Sequelize.STRING(100),
        allowNull: true,
      },
      cs_sentiment_score: {
        type: Sequelize.DECIMAL(5, 2),
        allowNull: true,
      },
      cs_urgency_score: {
        type: Sequelize.DECIMAL(5, 2),
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.fn('NOW'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.fn('NOW'),
      },
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('tbl_chatbot_sessions');
  },
};
