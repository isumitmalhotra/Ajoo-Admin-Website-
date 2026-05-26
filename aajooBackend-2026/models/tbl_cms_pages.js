'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_cms_pages extends Model {
    static associate(models) { }
  }
  tbl_cms_pages.init({
    cp_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    cp_page_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false
    },
    cp_section_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false
    },
    cp_title: {
      type: DataTypes.STRING,
      allowNull: true
    },
    cp_description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    cp_afile_id: {
      type: DataTypes.INTEGER(11),
      allowNull: true
    },
    cp_bt_title: {
      type: DataTypes.STRING,
      allowNull: true
    },
    cp_btn_url: {
      type: DataTypes.STRING,
      allowNull: true
    },
    cp_btn_opn: {
      type: DataTypes.STRING,
      allowNull: true
    },
    cp_hm_props: {
      type: DataTypes.JSON,
      allowNull: true
    },
    cp_hm_faq: {
      type: DataTypes.JSON,
      allowNull: true
    },
    cp_hm_testimonial: {
      type: DataTypes.JSON,
      allowNull: true
    }
  }, {
    sequelize,
    modelName: 'tbl_cms_pages',
    timestamps: true,
  });
  return tbl_cms_pages;
};