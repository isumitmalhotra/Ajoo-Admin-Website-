'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_user_otp extends Model {

    static associate(models) {
      // define association here
    }
    static async addOtp(userId, otp) {
      try {
        await tbl_user_otp.destroy({ where: { uo_userId: userId } });
        await tbl_user_otp.create({ uo_userId: userId, uo_otp: otp });
      } catch (error) {
        return error
      }
    };
    static async findOtp(whereClause) {
      try {
        const data = await tbl_user_otp.findOne({
          raw: true,
          where: whereClause
        });
        return data;
      } catch (error) {
        return error
      }
    };


  }
  tbl_user_otp.init({
    uo_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    uo_userId: DataTypes.INTEGER(11),
    uo_otp: DataTypes.STRING(20),
  }, {
    sequelize,
    modelName: 'tbl_user_otp',
    timestamps: true,
    createdAt: "uo_createdAt",
    updatedAt: false
  });
  return tbl_user_otp;
};