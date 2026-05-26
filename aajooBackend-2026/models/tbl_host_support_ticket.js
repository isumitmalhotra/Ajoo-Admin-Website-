'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_host_support_ticket extends Model {
    static associate(models) { }
  }
  tbl_host_support_ticket.init({
    hst_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false,
    },
    hst_host_id: DataTypes.INTEGER(11),
    hst_subject: DataTypes.STRING(255),
    hst_category: DataTypes.STRING(100),
    hst_priority: DataTypes.STRING(20),
    hst_status: DataTypes.STRING(20),
    hst_description: DataTypes.TEXT(),
    hst_resolution_note: DataTypes.TEXT(),
    hst_is_active: DataTypes.TINYINT(1),
    hst_is_deleted: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_host_support_ticket',
    tableName: 'tbl_host_support_tickets',
  });
  return tbl_host_support_ticket;
};
