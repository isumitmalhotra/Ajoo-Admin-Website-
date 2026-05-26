'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_admins extends Model {
    static associate(models) { }

    static async findAdmin(whereClause, attributes) {
      try {
        const data = await tbl_admins.findOne({
          raw: true,
          where: whereClause,
          // attributes: attributes
        });
        return data;
      } catch (error) {
        return error
      }
    }
  }
  tbl_admins.init({
    admin_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    admin_name: DataTypes.STRING(100),
    admin_username: DataTypes.STRING(100),
    admin_email: DataTypes.STRING(100),
    admin_password: DataTypes.STRING(255),
    admin_last_login: DataTypes.DATE(),
    admin_isAdmin: DataTypes.TINYINT(1),
    admin_isActive: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_admins',
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
  });
  return tbl_admins;
};