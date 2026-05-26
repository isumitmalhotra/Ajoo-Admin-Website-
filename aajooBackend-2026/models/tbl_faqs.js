'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class tbl_faqs extends Model {
    static associate(models) {
      // If you later add FAQ categories you can associate here
    }
  }

  tbl_faqs.init(
    {
      faq_id: {
        type: DataTypes.INTEGER(11),
        primaryKey: true,
        allowNull: false,
        autoIncrement: true,
      },

      faq_question: {
        type: DataTypes.STRING(255),
        allowNull: false,
      },

      faq_answer: {
        type: DataTypes.TEXT,
        allowNull: false,
      },

      faq_category: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },

      faq_display_order: {
        type: DataTypes.INTEGER(11),
        allowNull: true,
        defaultValue: 0,
      },

      faq_is_active: {
        type: DataTypes.TINYINT(1),
        allowNull: false,
        defaultValue: 1, // 1 = active, 0 = inactive
      },

      faq_is_delete: {
        type: DataTypes.TINYINT(1),
        allowNull: false,
        defaultValue: 0, // 0 = not deleted, 1 = deleted
      },

      faq_created_by: {
        type: DataTypes.INTEGER(11),
        allowNull: true,
      },

      faq_updated_by: {
        type: DataTypes.INTEGER(11),
        allowNull: true,
      }
    },
    {
      sequelize,
      modelName: "tbl_faqs",
      tableName: "tbl_faqs",
      timestamps: true,
      createdAt: "faq_created_at",
      updatedAt: "faq_updated_at",
    }
  );

  return tbl_faqs;
};