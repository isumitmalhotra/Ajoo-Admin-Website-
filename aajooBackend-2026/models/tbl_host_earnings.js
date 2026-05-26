'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_host_earnings extends Model {
    static associate(models) { }

    static getTotalEarnings(whereClause) {
      try {
        const data = tbl_host_earnings.sum("he_amount", {
          where: { ...whereClause },
        });
        return data;
      } catch (error) {
        return error
      }
    }
  }
  tbl_host_earnings.init({
    he_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    he_booking_id: DataTypes.INTEGER(11),
    he_host_id: DataTypes.INTEGER(11),
    he_payment_id: DataTypes.INTEGER(11),
    he_amount: DataTypes.DOUBLE(10, 2),
    he_invoice: DataTypes.TEXT(),
    he_status: DataTypes.INTEGER(11),
    he_isRecieved: DataTypes.TINYINT(1),
    he_isDeleted: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_host_earnings',
  });
  return tbl_host_earnings;
};