'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_blog_to_tag extends Model {
    static associate(models) { }
  }
  tbl_blog_to_tag.init({
    btt_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    btt_tag_id: DataTypes.INTEGER(11),
    btt_blog_id: DataTypes.INTEGER(11),
  }, {
    sequelize,
    modelName: 'tbl_blog_to_tag',
    timestamps: false
  });
  return tbl_blog_to_tag;
};