'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_notify_device extends Model {
    static associate(models) {

    }
  }
  tbl_notify_device.init({
    nd_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true,
    },
    nd_user_id: DataTypes.INTEGER(11),
    nd_user_email: DataTypes.STRING(100),
    nd_device_type: DataTypes.TINYINT(1),
    nd_device_token: DataTypes.TEXT(),
  }, {
    sequelize,
    modelName: 'tbl_notify_device',
  });
  return tbl_notify_device;
};