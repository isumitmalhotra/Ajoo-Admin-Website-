'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_book_history extends Model {
    static associate(models) {
      tbl_book_history.belongsTo(models.tbl_properties, { foreignKey: "bh_prop_id", targetKey: "property_id", as: "hisProperty" })
      tbl_book_history.belongsTo(models.tbl_book_status, { foreignKey: "bh_status_id", targetKey: "bs_id", as: "hisStatus" })
    }

  }
  tbl_book_history.init({
    bh_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    bh_book_id: DataTypes.INTEGER(11),
    bh_user_id: DataTypes.INTEGER(11),
    bh_host_id: DataTypes.INTEGER(11),
    bh_prop_id: DataTypes.INTEGER(11),
    bh_pay_id: DataTypes.INTEGER(11),
    bh_price: DataTypes.DOUBLE(10, 2),
    bh_status_id: DataTypes.INTEGER(11),
    bh_title: DataTypes.STRING(100),
    bh_description: DataTypes.STRING(255),
  }, {
    sequelize,
    modelName: 'tbl_book_history',
    timestamps: true,
    createdAt: "bh_addedAt",
    updatedAt: "bh_updatedAt",
  });
  return tbl_book_history;
};