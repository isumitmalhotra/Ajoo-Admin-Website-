'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_coupons extends Model {

    static associate(models) {
      // define association here
    }
  }
  tbl_coupons.init({
    cpn_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    cpn_title: DataTypes.STRING(255),
    cpn_code: DataTypes.STRING(100),
    cpn_type: DataTypes.TINYINT(1),
    cpn_dsctn_type: DataTypes.INTEGER(11),
    cpn_dsctn_percnt: DataTypes.INTEGER(11),
    cpn_dsctn_amt: DataTypes.DOUBLE(10, 2),
    cpn_min_amt: DataTypes.DOUBLE(10, 2),
    cpn_max_amt: DataTypes.DOUBLE(10, 2),
    cpn_valid_from: DataTypes.DATE,
    cpn_valid_to: DataTypes.DATE,
    cpn_usage_limit: DataTypes.INTEGER(11),
    cpn_used_count: DataTypes.INTEGER(11),
    cpn_status: DataTypes.TINYINT(1),
    cpn_isDeleted: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_coupons',
    timestamps: true,
  });
  return tbl_coupons;
};