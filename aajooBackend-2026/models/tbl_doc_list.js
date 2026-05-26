'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_doc_list extends Model {

    static associate(models) { }
    static async getDocList() {
      return this.findAll({
        attributes: ['d_id', 'd_title'],
        order: [['d_id', 'DESC']]
      });
    };
  }
  tbl_doc_list.init({
    d_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false,
    },
    d_title: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
  }, {
    sequelize,
    modelName: 'tbl_doc_list',
  });
  return tbl_doc_list;
};