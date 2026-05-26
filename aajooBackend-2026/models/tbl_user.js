'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_user extends Model {

    static associate(models) {
      tbl_user.belongsTo(models.tbl_user_cred, { foreignKey: "user_id", targetKey: "cred_user_id", as: "userCred" })
      tbl_user.belongsTo(models.tbl_attachments, { foreignKey: "user_id", targetKey: "afile_record_id", as: "UserAttachements" })
      tbl_user.belongsTo(models.user_kyc_docs, { foreignKey: "user_id", targetKey: "ud_user_id", as: "userKycDocs" })
      tbl_user.belongsTo(models.tbl_properties, { foreignKey: "user_id", targetKey: "property_host_id", as: "hostProperty" })
      tbl_user.hasMany(models.tbl_messages, {
        foreignKey: 'sender_id',
        as: 'sentMessages',
      });

      // 📥 User received messages
      tbl_user.hasMany(models.tbl_messages, {
        foreignKey: 'receiver_id',
        as: 'receivedMessages',
      });
    }
    static async createUser(payload) {
      try {
        const data = await tbl_user.create(payload);
        return data;
      } catch (error) {
        return error
      }
    };
    static async updateUser(payload, id) {
      try {
        const data = await tbl_user.update(payload, { where: { user_id: id } });
        return data;
      } catch (error) {
        return error
      }
    };
    static async findUser(whereClause, attributes) {
      try {
        const data = await tbl_user.findOne({
          raw: true,
          where: whereClause,
          attributes: attributes
        });
        return data;
      } catch (error) {
        throw error;
      }
    };
  }
  tbl_user.init({
    user_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      allowNull: false,
      autoIncrement: true,
    },
    user_fullName: DataTypes.STRING(100), // Increase from 50 to 100 or more
    user_pnumber: DataTypes.STRING(100),
    user_dob: DataTypes.STRING(20),
    user_address: DataTypes.STRING(255),
    user_city: DataTypes.STRING(100), // Increase length if needed
    user_zipcode: DataTypes.STRING(20),
    user_isHost: DataTypes.TINYINT(1),
    user_isUser: DataTypes.TINYINT(1),
    user_isActive: DataTypes.TINYINT(1),
    user_isVerified: DataTypes.TINYINT(1),
    user_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_user',
    timestamps: true,
    createdAt: "added_at",
    updatedAt: "updated_at",
  });

  return tbl_user;
};