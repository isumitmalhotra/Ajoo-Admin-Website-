'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class tbl_bookings extends Model {
    static associate(models) {
      tbl_bookings.belongsTo(sequelize.models.tbl_book_details, { foreignKey: "book_pri_id", targetKey: "bt_book_pri_id", as: "bookDetails" });
      tbl_bookings.belongsTo(sequelize.models.tbl_user, { foreignKey: "book_user_id", targetKey: "user_id", as: "userDetails" });
      tbl_bookings.belongsTo(sequelize.models.tbl_properties, { foreignKey: "book_prop_id", targetKey: "property_id", as: "bookingProperty" });
      tbl_bookings.belongsTo(sequelize.models.tbl_book_status, { foreignKey: "book_status", targetKey: "bs_id", as: "bookingStatus" });
      tbl_bookings.belongsTo(sequelize.models.tbl_reviews, { foreignKey: "book_id", targetKey: "br_book_id", as: "bookingReview" });
    };

    static async createBooking(payload) {
      try {
        const data = await tbl_bookings.create(payload);
        return data.dataValues;
      } catch (error) {
        return error;
      }
    };
    static async updateBooking(payload, bookPriId) {
      try {
        await tbl_bookings.update(payload, { where: { book_pri_id: bookPriId } });
      } catch (error) {
        return error
      }
    };
    static async getBookings(whereClause, attributes) {
      try {
        const data = await tbl_bookings.findOne({
          raw: true,
          where: whereClause,
          attributes: attributes
        });
        return data;
      } catch (error) {
        return error
      }
    };
  };
  tbl_bookings.init({
    book_pri_id: {
      type: DataTypes.INTEGER(11),
      allowNull: false,
      primaryKey: true,
      autoIncrement: true
    },
    book_id: DataTypes.STRING(100),
    book_invoice: DataTypes.STRING(100),
    book_prop_id: DataTypes.INTEGER(11),
    book_prop_type: DataTypes.INTEGER(11),
    book_user_id: DataTypes.INTEGER(11),
    book_host_id: DataTypes.INTEGER(11),
    book_price: DataTypes.DOUBLE(10, 2),
    book_tax: DataTypes.DOUBLE(10, 2),
    book_tax_percentagenatage: DataTypes.DOUBLE(10, 2),
    book_total_amt: DataTypes.DOUBLE(10, 2),
    book_is_paid: DataTypes.TINYINT(1),
    book_is_cod: DataTypes.TINYINT(1),
    book_status: DataTypes.INTEGER(11),
    book_no_of_guests: DataTypes.INTEGER(11),
    book_no_of_beds: DataTypes.INTEGER(11),
    book_is_delete: DataTypes.TINYINT(1),
  }, {
    sequelize,
    modelName: 'tbl_bookings',
    timestamps: true,
    createdAt: "book_added_at",
    updatedAt: "book_updated_at"
  });
  return tbl_bookings;
};