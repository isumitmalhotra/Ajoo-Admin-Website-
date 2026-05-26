'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_book_details extends Model {
    static associate(models) { };

    static async createDetail(payload) {
      try {
        const data = await tbl_book_details.create(payload);
      } catch (error) {
        return error;
      }
    };
    static async updateDetail(payload, whereCluase) {
      try {
        await tbl_book_details.update(payload, { where: whereCluase });
      } catch (error) {
        return error
      }
    };  
  }
  tbl_book_details.init({
    bt_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    bt_book_pri_id: DataTypes.INTEGER(11),
    bt_book_id: DataTypes.STRING(100),
    bt_book_from: DataTypes.STRING(100),
    bt_book_to: DataTypes.STRING(100),
    bt_book_checkIn: DataTypes.STRING(10),
    bt_book_checkout: DataTypes.STRING(10),
    bt_book_status: DataTypes.INTEGER(11),
  }, {
    sequelize,
    modelName: 'tbl_book_details',
    timestamps: true,
    createdAt: "bt_added_at",
    updatedAt: "bt_update_at"
  });
  return tbl_book_details;
};