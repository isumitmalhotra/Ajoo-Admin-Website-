  'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_prop_to_cat extends Model {

    static associate(models) {
      tbl_prop_to_cat.belongsTo(models.tbl_properties, { foreignKey: 'pt_cat_prop_id', as: 'property' });
      tbl_prop_to_cat.belongsTo(models.tbl_categories, { foreignKey: 'pt_cat_cat_id', as: 'category' });
    }
    static async getCateId(whereClause) {
      try {
        const data = await tbl_prop_to_cat.findAll({
          raw: true,
          where: whereClause,
        });
        return data;
      } catch (error) {
        return error
      }
    }
    static async createPropCategories(categories, propId) {
      try {
        await tbl_prop_to_cat.destroy({ where: { pt_cat_prop_id: propId } });
        let catePayload = categories.map(cate => {
          return {
            pt_cat_cat_id: cate,
            pt_cat_prop_id: propId
          };
        });
        await tbl_prop_to_cat.bulkCreate(catePayload);
      } catch (error) {
        return error;
      }
    };
  }
  tbl_prop_to_cat.init({
    pt_cat_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      autoIncrement: true,
      primaryKey: true
    },
    pt_cat_cat_id: DataTypes.INTEGER(11),
    pt_cat_prop_id: DataTypes.INTEGER(11),
  }, {
    sequelize,
    modelName: 'tbl_prop_to_cat',
    timestamps: false,
  });
  return tbl_prop_to_cat;
};