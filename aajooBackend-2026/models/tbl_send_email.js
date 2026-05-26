'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_send_email extends Model {
    static associate(models) { }
  }
  tbl_send_email.init({
    se_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    se_user_id: DataTypes.INTEGER(11),
    se_recipient_email: DataTypes.STRING(255),
    se_subject: DataTypes.TEXT(),
    se_body: DataTypes.TEXT(),
    se_status: DataTypes.STRING(100),
    se_cc: DataTypes.STRING(255),
    se_bcc: DataTypes.STRING(255),
    se_attachment: DataTypes.TEXT(),
    se_template_id: DataTypes.INTEGER(11),
    se_mail_type: DataTypes.TEXT(),
  }, {
    sequelize,
    modelName: 'tbl_send_email',
  });
  return tbl_send_email;
};