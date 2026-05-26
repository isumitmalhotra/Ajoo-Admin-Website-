'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_payout_history extends Model {
    static associate(models) { }
  }
  tbl_payout_history.init({
    poh_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false,
    },
    poh_pay_req_id: DataTypes.INTEGER(11),
    poh_host_id: DataTypes.INTEGER(11),
    poh_amount: DataTypes.DOUBLE(10, 2),
    poh_invoice: DataTypes.STRING(255),
    poh_status: DataTypes.INTEGER(11),  
  }, {
    sequelize,
    modelName: 'tbl_payout_history',
  });
  return tbl_payout_history;
};