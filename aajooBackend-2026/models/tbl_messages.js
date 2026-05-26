'use strict';
const { Model, Op } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_messages extends Model {
    static associate(models) {
      tbl_messages.belongsTo(models.tbl_user, {
        foreignKey: 'sender_id',
        targetKey: 'user_id',
        as: 'sender'
      });

      tbl_messages.belongsTo(models.tbl_user, {
        foreignKey: 'receiver_id',
        targetKey: 'user_id',
        as: 'receiver'
      });
    }

    static async getConversation(senderId, receiverId) {
      try {
        const messages = await tbl_messages.findAll({
          where: {
            [Op.or]: [
              { sender_id: senderId, receiver_id: receiverId },
              { sender_id: receiverId, receiver_id: senderId }
            ]
          },
          order: [['created_at', 'ASC']],
          raw: true
        });

        return messages;
      } catch (error) {
        return error;
      }
    }
  }
  tbl_messages.init({
    message_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    sender_id: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    receiver_id: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    message: {
      type: DataTypes.TEXT(),
      allowNull: false
    },
    is_read: {
      type: DataTypes.TINYINT(1),
      defaultValue: 0
    },
    is_deleted: {
      type: DataTypes.TINYINT(1),
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'tbl_messages',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });
  return tbl_messages;
};