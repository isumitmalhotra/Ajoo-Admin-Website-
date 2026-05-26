'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_prop_to_amenities extends Model {
    static associate(models) {
      tbl_prop_to_amenities.belongsTo(models.tbl_properties, { foreignKey: 'pa_prop_id', as: 'property' });
      tbl_prop_to_amenities.belongsTo(models.tbl_amenities, { foreignKey: 'pa_amn_id', as: 'amenity' });
    };

    static async createPropAmenities(data, propId) {
      try {
        await tbl_prop_to_amenities.destroy({ where: { pa_prop_id: propId } });
        const payload = data.map(am => {
          return {
            pa_prop_id: propId,
            pa_amn_id: am
          };
        });
        await tbl_prop_to_amenities.bulkCreate(payload);
      } catch (error) {
        return error;
      }
    };
    static async getAmenitiesByPropId(whereClause) {
      try {
        const data = await tbl_prop_to_amenities.findAll({
          where: whereClause,
          attributes: ['pa_amn_id', "pa_prop_id"],
          raw:true
        });
        return data;
      } catch (error) {
        return error;
      }
    };
  }
  tbl_prop_to_amenities.init({
    pa_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    pa_prop_id: DataTypes.INTEGER(11),
    pa_amn_id: DataTypes.INTEGER(11),
  }, {
    sequelize,
    modelName: 'tbl_prop_to_amenities',
    timestamps: false
  });
  return tbl_prop_to_amenities;
};