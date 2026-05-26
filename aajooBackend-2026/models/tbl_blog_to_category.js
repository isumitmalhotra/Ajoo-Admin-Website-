'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_blog_to_category extends Model {
    static associate(models) { };

  }
  tbl_blog_to_category.init({
    btc_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true,
    },
    btc_cat_id: DataTypes.INTEGER(11),
    btc_blog_id: DataTypes.INTEGER(11),
  }, {
    sequelize,
    modelName: 'tbl_blog_to_category',
    timestamps: false
  });
  return tbl_blog_to_category;
};