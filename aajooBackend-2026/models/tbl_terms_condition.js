'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_terms_Condition extends Model {
    static associate(models) {
      // define association here
    }
  }
  tbl_terms_Condition.init({
    tc_id: {
      type: DataTypes.INTEGER(11),
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    tc_title: {
      type: DataTypes.STRING,
      allowNull: false
    },
    tc_description: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    tc_isActive: {
      type: DataTypes.TINYINT(1),
      allowNull: false,
      defaultValue: 1
    },
    tc_type: {
      type: DataTypes.TINYINT(1),
      allowNull: false,
      defaultValue: 1
    },
    tc_isdeleted: {
      type: DataTypes.TINYINT(1),
      allowNull: false,
      defaultValue: 0
    }
  }, {
    sequelize,
    modelName: 'tbl_terms_Condition',
    timestamps: true,
    createdAt: 'tc_created_at',
    updatedAt: 'tc_updated_at',
  });
  return tbl_terms_Condition;
};