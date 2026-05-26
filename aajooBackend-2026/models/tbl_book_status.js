'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_book_status extends Model {
    static associate(models) { };

    static async getSingleStatus(title) {
      try {
        const data = await tbl_book_status.findOne({
          raw: true,
          where: {
            bs_title: title,
            bs_isDelete: 0
          },
          attributes: { exclude: ["bs_isDelete"] }
        });
        return data;
      } catch (error) {
        return error;
      }
    };

  }
  tbl_book_status.init({
    bs_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    bs_title: DataTypes.STRING(100),
    bs_code: DataTypes.STRING(50),
    bs_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_book_status',
    timestamps: false
  });
  return tbl_book_status;
};