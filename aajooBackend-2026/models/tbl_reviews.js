'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_reviews extends Model {
    static associate(models) {
      tbl_reviews.belongsTo(models.tbl_user, { foreignKey: "br_userId", targetKey: "user_id", as: "userReview" })
      tbl_reviews.belongsTo(models.tbl_properties, { foreignKey: "br_propId", targetKey: "property_id", as: "propReview" })
      tbl_reviews.belongsTo(models.tbl_bookings, { foreignKey: "br_book_id", targetKey: "book_id", as: "bookReview" })
      tbl_reviews.belongsTo(models.tbl_review_likes, { foreignKey: "br_id", targetKey: "rl_review_id", as: "ReviewLikesDislikes" })
    }

    static async findSingleReview(whereClause, attributes) {
      try {
        const data = await tbl_reviews.findOne({
          raw: true,
          where: whereClause,
          attributes: attributes
        });
        return data;
      } catch (error) {
        return error
      }
    }
  }
  tbl_reviews.init({
    br_id: {
      type: DataTypes.INTEGER(11),
      autoIncrement: true,
      primaryKey: true,
      allowNull: false
    },
    br_book_id: DataTypes.STRING(250),
    br_propId: DataTypes.INTEGER(11),
    br_hostId: DataTypes.INTEGER(11),
    br_userId: DataTypes.INTEGER(11),
    br_rating: DataTypes.DECIMAL(10, 2),
    br_title: DataTypes.STRING(100),
    br_desc: DataTypes.TEXT(),
    br_isActive: DataTypes.TINYINT(1),
    br_isDelete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_reviews',
    timestamps: true,
    createdAt: "br_addedAt",
    updatedAt: "br_updatedAt"
  });
  return tbl_reviews;
};