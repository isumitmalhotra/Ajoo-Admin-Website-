'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_nagotiate_messages extends Model {
    static associate(models) {
      tbl_nagotiate_messages.belongsTo(models.tbl_properties, { foreignKey: 'property_id' });
      tbl_nagotiate_messages.belongsTo(models.tbl_user, { foreignKey: 'sender_id', as: 'Sender' });
      tbl_nagotiate_messages.belongsTo(models.tbl_user, { foreignKey: 'receiver_id', as: 'Receiver' });
    }
  }
  tbl_nagotiate_messages.init({
    message_id: {
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
    message_text: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    is_offer: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    offer_price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true,
    },
    is_accepted: {
      type: DataTypes.TINYINT(1),
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'tbl_nagotiate_messages',
    tableName: 'tbl_nagotiate_messages',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false,
  });
  return tbl_nagotiate_messages;
};
