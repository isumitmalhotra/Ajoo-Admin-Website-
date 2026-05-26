'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_platform_review extends Model {
    static associate(models) { }
  }
  tbl_platform_review.init({
    pr_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    pr_book_id: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    pr_user_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false
    },
    pr_host_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false
    },
    pr_rating: {
      type: DataTypes.TINYINT(1),
      allowNull: false
    },
    pr_title: {
      type: DataTypes.STRING(100),
      // allowNull: false
    },
    pr_description: {
      type: DataTypes.TEXT(),
      // allowNull: false
    },
    pr_isActive: {
      type: DataTypes.TINYINT(1),
      defaultValue: 1
    },
    pr_isDelete: {
      type: DataTypes.TINYINT(1),
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'tbl_platform_review',
  });
  return tbl_platform_review;
};