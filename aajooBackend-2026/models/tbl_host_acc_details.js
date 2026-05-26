'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_host_acc_details extends Model {
    static associate(models) { }
  }
  tbl_host_acc_details.init({
    had_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      autoIncrement: true,
      primaryKey: true
    },
    had_host_id: DataTypes.INTEGER(11),
    had_acc_no: DataTypes.STRING(255),
    had_ifsc: DataTypes.STRING(255),
    had_status: DataTypes.INTEGER(11),
    had_isVerified: DataTypes.TINYINT(1),
    had_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_host_acc_details',
  });
  return tbl_host_acc_details;
};