'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_blog_categories extends Model {
    static associate(models) { }
  }
  tbl_blog_categories.init({
    bc_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    bc_title: DataTypes.STRING(50),
    bc_description: DataTypes.STRING(200),
    bc_isActive: DataTypes.TINYINT(1),
    bc_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_blog_categories',
    timestamps: false
  });
  return tbl_blog_categories;
};