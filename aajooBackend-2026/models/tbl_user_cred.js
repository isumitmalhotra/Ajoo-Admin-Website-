'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_user_cred extends Model {
    static associate(models) { }

    static async findUser(whereCluase, attributes) {
      let att = attributes ?? ["cred_user_id", "cred_user_email","cred_user_isHost"]
      try {
        const data = await tbl_user_cred.findOne({
          raw: true,
          where: whereCluase,
          attributes: attributes ?? att
        });
        return data;
      } catch (error) {
        throw error
      }
    };
    static async createCredUser(payload) {
      try {
        await tbl_user_cred.create(payload);
      } catch (error) {
        throw error;
      }
    };
    static async updateCred(payload, userId) {
      try {
        await tbl_user_cred.update(payload, { where: { cred_user_id: userId } });
      } catch (error) {
        return error
      }
    };

  }
  tbl_user_cred.init({
    cred_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    cred_user_id: DataTypes.INTEGER(11),
    cred_username: DataTypes.STRING(100),
    cred_user_email: DataTypes.STRING(100),
    cred_user_password: DataTypes.STRING(200),
    // cred_user_doc_type: DataTypes.INTEGER(11),
    // cred_user_doc_number: DataTypes.STRING(50),
    cred_user_refrel: DataTypes.TINYINT(1),
    cred_user_isHost: DataTypes.TINYINT(1),
    cred_user_isUser: DataTypes.TINYINT(1),
    cred_user_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_user_cred',
    timestamps: false
  });
  return tbl_user_cred;
};