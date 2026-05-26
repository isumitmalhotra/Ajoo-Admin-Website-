'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class user_kyc_docs extends Model {


    static associate(models) {
      user_kyc_docs.belongsTo(models.tbl_doc_list, { foreignKey: "ud_acc_doc_id", targetKey: "d_id", as: "docType" });
      user_kyc_docs.belongsTo(models.tbl_attachments, { foreignKey: "ud_afile_id", targetKey: "afile_id", as: "docImage" });
    }

    static async createKycDoc(payload) {
      try {
        const data = await user_kyc_docs.create(payload);
        return data;
      } catch (error) {
        throw error;
      }
    }
  }
  user_kyc_docs.init({
    ud_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true,
    },
    ud_user_id: DataTypes.INTEGER(11),
    ud_acc_doc_id: DataTypes.INTEGER(11),
    ud_number: DataTypes.STRING(255),
    ud_afile_id: DataTypes.INTEGER(11),
    ud_isVerified: DataTypes.TINYINT(1)
  }, {
    sequelize,
    modelName: 'user_kyc_docs',
  });
  return user_kyc_docs;
};