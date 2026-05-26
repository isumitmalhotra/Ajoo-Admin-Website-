'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_cpn_dscount_typ extends Model {

    static associate(models) {
      // define association here
    }
  }
  tbl_cpn_dscount_typ.init({
    cdt_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    cdt_type: DataTypes.STRING(255),
    cdt_desc: DataTypes.STRING(255),
  }, {
    sequelize,
    modelName: 'tbl_cpn_dscount_typ',
    timestamps: true,
  });
  return tbl_cpn_dscount_typ;
};