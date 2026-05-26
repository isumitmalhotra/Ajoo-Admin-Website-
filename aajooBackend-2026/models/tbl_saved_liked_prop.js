'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_saved_liked_prop extends Model {
    static associate(models) { };

    static async createData(payload) {
      try {
        await tbl_saved_liked_prop.create(payload);
      } catch (error) {
        return error;
      }
    };

    static async getSingle(whereClause) {
      try {
        const data = await tbl_saved_liked_prop.findOne({
          raw: true,
          where: whereClause,
          attributes: [
            "slp_id",
            "slp_user_id",
            "slp_prop_id",
            "slp_isSave",
            "slp_isLike",
          ]
        });
        return data;
      } catch (error) {
        return error
      }
    };
    static async deleteData(whereClause) {
      try {
        await tbl_saved_liked_prop.destroy({ where: whereClause });
      } catch (error) {
        return error;
      }
    }
  }
  tbl_saved_liked_prop.init({
    slp_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    slp_user_id: DataTypes.INTEGER(11),
    slp_prop_id: DataTypes.INTEGER(11),
    slp_isSave: DataTypes.TINYINT(1),
    slp_isLike: DataTypes.TINYINT(1),
    slp_isDislike: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_saved_liked_prop',
    timestamps: false
  });
  return tbl_saved_liked_prop;
};