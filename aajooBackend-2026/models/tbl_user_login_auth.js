'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_user_login_auth extends Model {
    static associate(models) { };

    static async createLoginAuth(payload) {
      try {
        await tbl_user_login_auth.create(payload);
      } catch (error) {
        return error;
      }
    };
    
  }
  tbl_user_login_auth.init({
    la_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    la_user_id: DataTypes.INTEGER(11),
    la_token: DataTypes.TEXT({ length: "long" }),
    la_ip: DataTypes.STRING(100),
  }, {
    sequelize,
    modelName: 'tbl_user_login_auth',
    timestamps: true,
    createdAt: "la_addedAt",
    updatedAt: false
  });
  return tbl_user_login_auth;
};