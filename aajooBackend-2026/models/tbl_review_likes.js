'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_review_likes extends Model {
    static associate(models) {
    }
  }
  tbl_review_likes.init({
    rl_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    rl_review_id: DataTypes.INTEGER(11),
    rl_user_id: DataTypes.INTEGER(11),
    rl_like: DataTypes.TINYINT(1),
    rl_dislike: DataTypes.JSON(),
    rl_list: DataTypes.JSON(),
  }, {
    sequelize,
    modelName: 'tbl_review_likes',
    timestamps: false
  });
  return tbl_review_likes;
};