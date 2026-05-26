'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_host_review extends Model {
    static associate(models) { }
  }
  tbl_host_review.init({
    hr_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    hr_book_id: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    hr_user_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false
    },
    hr_host_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false
    },
    hr_rating: {
      type: DataTypes.TINYINT(1),
      allowNull: false
    },
    hr_title: {
      type: DataTypes.STRING(100),
      // allowNull: false
    },
    hr_description: {
      type: DataTypes.TEXT(),
      // allowNull: false
    },
    hr_isActive: {
      type: DataTypes.TINYINT(1),
      defaultValue: 1
    },
    hr_isDelete: {
      type: DataTypes.TINYINT(1),
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'tbl_host_review',
    // tableName: 'tbl_host_reviews',
  });
  return tbl_host_review;
};