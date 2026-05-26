'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_amenities extends Model {
    static associate(models) { };

    static async allData(whereClause) {
      try {
        const data = await tbl_amenities.findAll({
          raw: true,
          where: whereClause,
          attributes: ["amn_id", "amn_title"]
        });
        return data;
      } catch (error) {
        return error;
      }
    }

    static async getAmenety(whereClause) {
      try {
        const data = await tbl_amenities.findOne({
          raw: true,
          where: whereClause,
          attributes: ["amn_id", "amn_title", "amn_isActive"]
        });
        return data;
      } catch (error) {
        return error;
      }
    }

    static async createAmenity(payload) {
      try {
        const data = await tbl_amenities.create(payload);
        console.log(data);
      } catch (error) {
        return error;
      }
    }
    static async updateAmenity(amenityId, payload) {
      try {
        const data = await tbl_amenities.update(payload, {
          where: { amn_id: amenityId }
        });
        // return data;
      } catch (error) {
        return error;
      }
    }
  }
  tbl_amenities.init({
    amn_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    amn_title: DataTypes.STRING(20),
    amn_isActive: DataTypes.TINYINT(1),
    amn_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_amenities',
    timestamps: false
  });
  return tbl_amenities;
};