'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_payment extends Model {

    static associate(models) {
      tbl_payment.belongsTo(models.tbl_user, { foreignKey: 'pay_userId', targetKey: "user_id", as: 'userPayment' });
      tbl_payment.belongsTo(sequelize.models.tbl_properties, { foreignKey: "pay_propId", targetKey: "property_id", as: "paymentProperty" });
      tbl_payment.belongsTo(sequelize.models.tbl_book_status, { foreignKey: "pay_status", targetKey: "bs_id", as: "paymentStatus" });
    };

  }
  tbl_payment.init({
    pay_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    pay_raz_id: DataTypes.TEXT(),
    pay_order_id: DataTypes.TEXT(),
    pay_receipt_id: DataTypes.TEXT(),
    pay_bookId: DataTypes.TEXT(11),
    pay_book_pri_id: DataTypes.INTEGER(11),
    pay_userId: DataTypes.INTEGER(11),
    pay_hostId: DataTypes.INTEGER(11),
    pay_propId: DataTypes.INTEGER(11),
    pay_invoice: DataTypes.STRING(50),
    pay_amount: DataTypes.DECIMAL(10, 2),
    pay_status: DataTypes.INTEGER(11),
    pay_status_text: DataTypes.TEXT(),
  }, {
    sequelize,
    modelName: 'tbl_payment',
    createdAt: "pay_addedAt",
    updatedAt: "pay_updatedAt",
  });
  return tbl_payment;
};