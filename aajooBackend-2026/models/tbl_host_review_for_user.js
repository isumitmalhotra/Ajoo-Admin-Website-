'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_host_review_for_user extends Model {
    static associate(models) {
      tbl_host_review_for_user.belongsTo(models.tbl_user, { foreignKey: 'hru_userId', targetKey: "user_id", as: 'reviewUsername' });
      tbl_host_review_for_user.belongsTo(models.tbl_user, { foreignKey: 'hru_hostId', targetKey: "user_id", as: 'reviewHostName' });
      tbl_host_review_for_user.belongsTo(models.tbl_properties, { foreignKey: 'hru_propId', targetKey: "property_id", as: 'reviewProp' });
    }
  }
  tbl_host_review_for_user.init({
    hru_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
    },
    hru_hostId: DataTypes.INTEGER(11),
    hru_userId: DataTypes.INTEGER(11),
    hru_bookingPriId: DataTypes.INTEGER(11),
    hru_propId: DataTypes.INTEGER(11),
    hru_bookingId: DataTypes.TEXT,
    hru_title: DataTypes.STRING(255),
    hru_description: DataTypes.TEXT,
    hru_rating: DataTypes.DOUBLE(10, 2),
    hru_isActive: DataTypes.TINYINT(1),
    hru_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_host_review_for_user',
  });
  return tbl_host_review_for_user;
};