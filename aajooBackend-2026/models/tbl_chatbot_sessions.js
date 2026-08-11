'use strict';

const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class tbl_chatbot_sessions extends Model {
    static associate(models) {
      tbl_chatbot_sessions.belongsTo(models.tbl_user, {
        foreignKey: 'cs_user_id',
        targetKey: 'user_id',
        as: 'sessionUser',
      });
    }
  }

  tbl_chatbot_sessions.init(
    {
      cs_session_id: {
        type: DataTypes.STRING(255),
        allowNull: false,
        unique: true,
        primaryKey: true,
      },
      cs_channel_type: {
        type: DataTypes.STRING(50),
        allowNull: true,
        defaultValue: 'web',
      },
      cs_user_id: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      cs_user_name: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      cs_user_role: {
        type: DataTypes.STRING(50),
        allowNull: true,
      },
      cs_phone: {
        type: DataTypes.STRING(20),
        allowNull: true,
      },
      cs_language_pref: {
        type: DataTypes.STRING(10),
        allowNull: true,
        defaultValue: 'en',
      },
      cs_stage: {
        type: DataTypes.STRING(100),
        allowNull: true,
        defaultValue: 'language_selection',
      },
      cs_context: {
        type: DataTypes.JSON,
        allowNull: true,
      },
      cs_last_intent: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      cs_sentiment_score: {
        type: DataTypes.FLOAT,
        allowNull: true,
        defaultValue: 0,
      },
      cs_urgency_score: {
        type: DataTypes.FLOAT,
        allowNull: true,
        defaultValue: 0,
      },
    },
    {
      sequelize,
      modelName: 'tbl_chatbot_sessions',
      tableName: 'tbl_chatbot_sessions',
      timestamps: true,
      createdAt: 'created_at',
      updatedAt: 'updated_at',
    }
  );

  return tbl_chatbot_sessions;
};
