'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_tags extends Model {
    static associate(models) { };

    static async getTags(whereClause, att) {
      try {
        const data = await tbl_tags.findAll({
          raw: true,
          where: whereClause,
          attributes: att
        });
        return data;
      } catch (error) {
        return error;
      }
    }

    static async updateTag(id, payload) {
      try {
        const data = await tbl_tags.update(payload, { where: { tag_id: id } });
        return data;
      } catch (error) {
        return error;
      }
    }

    static async createTag(payload) {
      try {
        const data = await tbl_tags.create(payload);
        return data;
      } catch (error) {
        return error;
      }
    }
  }
  tbl_tags.init({
    tag_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    tag_name: DataTypes.STRING(50),
    tag_isActive: DataTypes.TINYINT(1),
    tag_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_tags',
    timestamps: false
  });
  return tbl_tags;
};