'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_cms_section extends Model {

    static associate(models) {
      // define association here
    }
  }
  tbl_cms_section.init({
    cs_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    cs_title: {
      type: DataTypes.STRING,
      allowNull: false
    },
    cs_slug: {
      type: DataTypes.STRING,
      allowNull: false
    },
    cs_isActive: {
      type: DataTypes.TINYINT(1),
      allowNull: false,
      defaultValue: true
    },
    cs_url: {
      type: DataTypes.STRING,
      allowNull: true
    },
    cs_description: {
      type: DataTypes.TEXT,
      // allowNull: true
    },
    cs_content: {
      type: DataTypes.TEXT('long'),
      // allowNull: true
    },
    cs_image: {
      type: DataTypes.STRING,
      // allowNull: true
    },
    cs_order: {
      type: DataTypes.INTEGER,
      // allowNull: true
    }
  }, {
    sequelize,
    modelName: 'tbl_cms_section',
    timestamps: true,
    createdAt: 'cs_created_at',
    updatedAt: 'cs_updated_at',
  });
  return tbl_cms_section;
};