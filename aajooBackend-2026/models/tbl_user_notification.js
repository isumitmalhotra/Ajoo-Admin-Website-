'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_user_notification extends Model {
    static associate(models) {
    }
  }
  tbl_user_notification.init({
    un_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    un_userId: DataTypes.INTEGER(11),
    un_propId: DataTypes.INTEGER(11),
    un_bookingId: DataTypes.STRING(255),
    un_pri_bookingId: DataTypes.INTEGER(11),
    un_title: DataTypes.STRING(100),
    un_message: DataTypes.TEXT(),
    un_is_read: DataTypes.TINYINT(1),
    un_payload: DataTypes.JSON(500),
  }, {
    sequelize,
    modelName: 'tbl_user_notification',
  });
  return tbl_user_notification;
};