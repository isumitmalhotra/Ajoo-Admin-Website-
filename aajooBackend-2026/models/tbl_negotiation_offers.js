'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_negotiation_offers extends Model {
    static associate(models) {
      tbl_negotiation_offers.belongsTo(models.tbl_properties, { foreignKey: 'property_id' });
      tbl_negotiation_offers.belongsTo(models.tbl_user, { foreignKey: 'renter_id', as: 'Renter' });
    }
  }
  tbl_negotiation_offers.init({
    offer_id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    property_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    sender_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    receiver_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    offer_price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
    offer_message_text: {
      type: DataTypes.TEXT,
      // allowNull: false,
    },
    offer_number: {
      type: DataTypes.INTEGER,
      allowNull: false,
    }
  }, {
    sequelize,
    modelName: 'tbl_negotiation_offers',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false,
  });
  return tbl_negotiation_offers;
};