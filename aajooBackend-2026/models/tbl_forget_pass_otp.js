'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_forget_pass_otp extends Model {
    static associate(models) {
      // define association here
    }
  }
  tbl_forget_pass_otp.init({
    fpo_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    fpo_userId: DataTypes.INTEGER(11),
    fpo_otp: DataTypes.STRING(50),
    fpo_email: DataTypes.STRING(100),
    fpo_type: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_forget_pass_otp',
  });
  return tbl_forget_pass_otp;
};