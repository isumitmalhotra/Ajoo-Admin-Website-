'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_history extends Model {
    static associate(models) { };
  }
  tbl_history.init({
    his_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    his_bookId: DataTypes.INTEGER(11),
    his_propId: DataTypes.INTEGER(11),
    his_userId: DataTypes.INTEGER(11),
    his_hostId: DataTypes.INTEGER(11),
    his_status: DataTypes.INTEGER(11),
    his_title: DataTypes.STRING(100),
    his_desc: DataTypes.TEXT(),

  }, {
    sequelize,
    modelName: 'tbl_history',
    timestamps: true,
    createdAt: "his_addedAt",
    updatedAt: "his_updatedAt",
  });
  return tbl_history;
};