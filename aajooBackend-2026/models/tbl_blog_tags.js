'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_blog_tags extends Model {
    static associate(models) { }
  }
  tbl_blog_tags.init({
    bt_id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    bt_title: DataTypes.STRING(50),
    bt_isActive: DataTypes.TINYINT(1),
    bt_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_blog_tags',
    timestamps: false
  });
  return tbl_blog_tags;
};