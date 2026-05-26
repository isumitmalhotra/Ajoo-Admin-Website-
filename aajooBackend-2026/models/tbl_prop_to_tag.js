'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_prop_to_tag extends Model {
    static associate(models) {
      tbl_prop_to_tag.belongsTo(models.tbl_properties, { foreignKey: 'pt_tag_prop_id', as: 'property' });
      tbl_prop_to_tag.belongsTo(models.tbl_tags, { foreignKey: 'pt_tag_tag_id', as: 'tag' });
    };

    static async getTagToProp(whereClause) {
      try {
        const data = await tbl_prop_to_tag.findAll({
          raw: true,
          where: whereClause,
          attributes: ["pt_tag_tag_id", "pt_tag_prop_id"],
        });
        return data;
      } catch (error) {
        return error
      }
    };
    static async createPropertyTag(tags, propId) {
      try {
        await tbl_prop_to_tag.destroy({ where: { pt_tag_prop_id: propId } });
        const tagPayload = tags.map(tag => {
          return {
            pt_tag_prop_id: propId,
            pt_tag_tag_id: tag
          };
        });
        await tbl_prop_to_tag.bulkCreate(tagPayload);
      } catch (error) {

      }
    }
  }
  tbl_prop_to_tag.init({
    pt_tag_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true,
    },
    pt_tag_tag_id: DataTypes.INTEGER(11),
    pt_tag_prop_id: DataTypes.INTEGER(11),
  }, {
    sequelize,
    modelName: 'tbl_prop_to_tag',
    timestamps: false
  });
  return tbl_prop_to_tag;
};