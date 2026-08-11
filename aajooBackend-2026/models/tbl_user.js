'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_user extends Model {

    static associate(models) {
      tbl_user.hasOne(models.tbl_user_cred, { foreignKey: "cred_user_id", sourceKey: "user_id", as: "userCred" })
      tbl_user.hasMany(models.tbl_attachments, { foreignKey: "afile_record_id", sourceKey: "user_id", as: "UserAttachements" })
      tbl_user.hasOne(models.user_kyc_docs, { foreignKey: "ud_user_id", sourceKey: "user_id", as: "userKycDocs" })
      tbl_user.hasMany(models.tbl_properties, { foreignKey: "property_host_id", sourceKey: "user_id", as: "hostProperty" })
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
    // KYC (A-11)
    didit_session_id: DataTypes.STRING(64),
    verification_status: DataTypes.ENUM('unverified', 'pending', 'verified', 'declined', 'in_review'),
    verified_at: DataTypes.DATE,
    verification_expires_at: DataTypes.DATE,
  }, {
    sequelize,
    modelName: 'tbl_user',
    timestamps: true,
    createdAt: "added_at",
    updatedAt: "updated_at",
    indexes: [
      {
        fields: ['user_isDelete', 'user_isActive'],
        name: 'idx_tbl_user_status_deleted',
      },
      {
        fields: ['user_isHost', 'user_isDelete'],
        name: 'idx_tbl_user_host_deleted',
      },
    ]
  });

  return tbl_user;
};
