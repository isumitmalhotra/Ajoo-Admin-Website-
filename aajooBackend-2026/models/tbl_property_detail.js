'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_property_detail extends Model {
    static associate(models) { };

    static async createData(payload) {
      try {
        const dtat = await tbl_property_detail.create(payload);
      } catch (error) {
        return error;
      }
    };
    static async updateData(payload, propId) {
      try {
        await tbl_property_detail.update(payload, { where: { propDetail_propId: propId } });
      } catch (error) {
        return error;
      }
    };
  }
  tbl_property_detail.init({
    propDetail_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    propDetail_propId: DataTypes.INTEGER(11),
    propDetail_isPetFriendly: DataTypes.TINYINT(1),
    propDetail_isSmoke: DataTypes.TINYINT(1),
    propDetail_inTime: DataTypes.STRING(50),
    propDetail_outTime: DataTypes.STRING(50),
    propDetail_no_of_beds: DataTypes.STRING(250),
    propDetail_no_of_guests: DataTypes.INTEGER(11),
    propDetail_weeklyMini_price: DataTypes.DOUBLE(10, 2),
    propDetail_weeklyMax_price: DataTypes.DOUBLE(10, 2),
    propDetail_monthly_security: DataTypes.DOUBLE(10, 2),
    propDetail_extra: DataTypes.TEXT({ length: "long" }),
  }, {
    sequelize,
    modelName: 'tbl_property_detail',
    tableName: 'tbl_property_details',
    timestamps: false
  });
  return tbl_property_detail;
};