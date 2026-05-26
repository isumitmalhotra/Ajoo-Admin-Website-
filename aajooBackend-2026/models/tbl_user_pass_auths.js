'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_user_pass_auths extends Model {
    static associate(models) { };

    static async deleteData(userId) {
      try {
        await tbl_user_pass_auths.destroy({ where: { upa_userId: userId } });
      } catch (error) {
        return error
      }
    };

    static async createData(payload) {
      try {
        await tbl_user_pass_auths.create(payload);
      } catch (error) {
        return error
      }
    }
  }
  tbl_user_pass_auths.init({
    upa_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    upa_userId: DataTypes.INTEGER(11),
    upa_token: DataTypes.TEXT(),
    // upa_otp: DataTypes.TEXT(),
  }, {
    sequelize,
    modelName: 'tbl_user_pass_auths',
    timestamps: true,
    createdAt: "upa_addedAt",
    updatedAt: "upa_updatedAt",
  });
  return tbl_user_pass_auths;
};