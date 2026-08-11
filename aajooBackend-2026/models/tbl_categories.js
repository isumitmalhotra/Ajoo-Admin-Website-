'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_categories extends Model {

    static associate(models) { };

    static async getCategories(whereClause, att) {
      try {
        const data = await tbl_categories.findAll({
          raw: true,
          where: whereClause,
          attributes: att
        });
        return data
      } catch (error) {
        return error
      }
    };
    static async createCategory(payload) {
      try {
        const data = await tbl_categories.create(payload)
        return data;
      } catch (error) {
        return error
      }
    };

    static async updateCategory(id, payload) {
      try {
        const data = await tbl_categories.update(payload, {
          where: { cat_id: id }
        });
        return data;
      } catch (error) {
        return error
      }
    }
  }
  tbl_categories.init({
    cat_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      autoIncrement: true,
      primaryKey: true
    },
    cat_title: DataTypes.STRING(200),
    cat_slug: DataTypes.STRING(255),
    cat_isActive: DataTypes.STRING(200),
    cat_isDelete: DataTypes.STRING(200),
  }, {
    sequelize,
    modelName: 'tbl_categories',
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      {
        unique: true,
        fields: ['cat_slug', 'cat_isDelete'],
        name: 'uq_tbl_categories_slug_deleted',
      },
      {
        fields: ['cat_isActive', 'cat_isDelete'],
        name: 'idx_tbl_categories_status_deleted',
      },
    ]
  });
  return tbl_categories;
};
